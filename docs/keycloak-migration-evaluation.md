# UnityAuth to Keycloak Migration Evaluation

This document evaluates the changes required to replace UnityAuth with Keycloak in Libre311, including code changes and Google Cloud deployment considerations.

## Executive Summary

| Aspect | Complexity | Effort Estimate |
|--------|------------|-----------------|
| Backend Code Changes | Medium | Significant refactoring |
| Frontend Code Changes | Low-Medium | Moderate refactoring |
| Permission System | High | Major redesign required |
| Google Cloud Deployment | Medium | Standard GKE/Cloud Run setup |
| Testing Updates | Medium | Update all mocks and fixtures |

**Key Challenge:** UnityAuth uses a custom permission-checking API (`/api/hasPermission`) that doesn't exist in standard Keycloak. This requires either implementing a custom Keycloak extension or moving permission logic entirely into the Libre311 backend.

---

## Part 1: Current UnityAuth Architecture

### 1.1 Authentication Flow

```
┌─────────────┐     POST /api/login      ┌─────────────┐
│   Frontend  │ ─────────────────────────▶│  UnityAuth  │
│  (SvelteKit)│                          │   Service   │
└──────┬──────┘                          └──────┬──────┘
       │                                        │
       │◀───── JWT Token (access_token) ────────┘
       │
       │  GET /{jurisdictionId}/principal/permissions
       ▼       (with Bearer token)
┌─────────────┐                          ┌─────────────┐
│   Libre311  │ ───POST /api/hasPermission──▶│  UnityAuth  │
│   Backend   │◀────── permissions list ─────│   Service   │
└─────────────┘                          └─────────────┘
```

### 1.2 UnityAuth API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/login` | POST | Authenticate user, return JWT |
| `/keys` | GET | JWKS endpoint for JWT validation |
| `/api/hasPermission` | POST | Check if user has specific permissions |
| `/api/principal/permissions` | POST | Get all user permissions for a service |

### 1.3 UnityAuth Request/Response Contracts

**Login Request:**
```json
{
  "username": "user@example.com",
  "password": "password123"
}
```

**Login Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600,
  "username": "user@example.com"
}
```

**HasPermission Request:**
```json
{
  "tenantId": 1,
  "serviceId": 1,
  "permissions": ["LIBRE311_ADMIN_EDIT-SYSTEM", "LIBRE311_ADMIN_EDIT-TENANT"]
}
```

**HasPermission Response:**
```json
{
  "hasPermission": true,
  "userEmail": "user@example.com",
  "errorMessage": null,
  "permissions": ["LIBRE311_ADMIN_EDIT-TENANT"]
}
```

### 1.4 Permission Model

UnityAuth manages permissions with a hierarchical structure:

| Permission | Level | Description |
|------------|-------|-------------|
| `LIBRE311_ADMIN_EDIT-SYSTEM` | System | Full system-wide admin |
| `LIBRE311_ADMIN_VIEW-SYSTEM` | System | System-wide read access |
| `LIBRE311_ADMIN_EDIT-TENANT` | Tenant | Tenant-level admin |
| `LIBRE311_ADMIN_VIEW-TENANT` | Tenant | Tenant-level read access |
| `LIBRE311_ADMIN_EDIT-SUBTENANT` | Subtenant | Jurisdiction-level admin |
| `LIBRE311_ADMIN_VIEW-SUBTENANT` | Subtenant | Jurisdiction-level read access |
| `LIBRE311_REQUEST_EDIT-*` | Various | Service request editing |
| `LIBRE311_REQUEST_VIEW-*` | Various | Service request viewing |

**Key Concept:** UnityAuth validates permissions against `tenantId` + `serviceId` pairs, enabling multi-tenant isolation.

---

## Part 2: Keycloak Feature Mapping

### 2.1 Direct Equivalents

| UnityAuth Feature | Keycloak Equivalent |
|-------------------|---------------------|
| JWT Authentication | Native OAuth2/OIDC |
| JWKS Endpoint | `/realms/{realm}/protocol/openid-connect/certs` |
| User Login | `/realms/{realm}/protocol/openid-connect/token` |
| User Info | `/realms/{realm}/protocol/openid-connect/userinfo` |

### 2.2 Features Requiring Custom Implementation

| UnityAuth Feature | Keycloak Approach |
|-------------------|-------------------|
| `POST /api/hasPermission` | **No direct equivalent** - Options below |
| Multi-tenant permission checking | Requires custom solution |
| `serviceId` scoping | Custom client roles or attributes |

### 2.3 Options for Permission Checking

**Option A: Move Permission Logic to Libre311 Backend (Recommended)**
- Embed permissions in JWT claims via Keycloak mappers
- Validate permissions locally in `RequiresPermissionsAnnotationRule`
- Eliminates network calls for every protected request
- Maintains multi-tenant support via custom claims

**Option B: Keycloak Authorization Services**
- Use Keycloak's built-in Authorization Services (UMA 2.0)
- Complex setup, may not fit current permission model
- Requires Policy Enforcement Point (PEP) integration

**Option C: Custom Keycloak SPI Extension**
- Develop custom REST endpoint in Keycloak
- Mimics `/api/hasPermission` behavior
- Significant development effort
- Maintains compatibility with current code

**Recommendation:** Option A provides the best balance of simplicity, performance, and maintainability.

---

## Part 3: Backend Code Changes

### 3.1 Files Requiring Modification

| File | Change Type | Description |
|------|-------------|-------------|
| `app/security/UnityAuthClient.java` | **Delete or Replace** | HTTP client for UnityAuth |
| `app/security/UnityAuthService.java` | **Major Rewrite** | Replace with Keycloak/local logic |
| `app/security/RequiresPermissionsAnnotationRule.java` | **Modify** | Use JWT claims instead of API calls |
| `app/security/HasPermissionRequest.java` | **Delete** | No longer needed |
| `app/security/HasPermissionResponse.java` | **Delete** | No longer needed |
| `app/security/UnityAuthUserPermissionsRequest.java` | **Delete** | No longer needed |
| `app/security/UserPermissionsResponse.java` | **Modify** | Adapt to Keycloak token format |
| `app/PermissionsController.java` | **Modify** | Parse JWT claims locally |
| `application.yml` | **Modify** | Update JWKS and auth URLs |
| `application-*.yml` (all profiles) | **Modify** | Environment-specific Keycloak URLs |

### 3.2 New Files to Create

| File | Purpose |
|------|---------|
| `app/security/KeycloakSecurityService.java` | JWT claim parsing and validation |
| `app/security/KeycloakClaimParser.java` | Extract roles/permissions from JWT |
| `app/config/KeycloakConfig.java` | Configuration properties class |

### 3.3 Detailed Code Changes

#### 3.3.1 Replace UnityAuthService

Current implementation makes HTTP calls to UnityAuth:

```java
// Current: UnityAuthService.java (lines 68-93)
public boolean isUserPermittedForTenantAction(String token, Long tenantId, List<Permission> permissions) {
    HasPermissionRequest hasPermissionRequest = new HasPermissionRequest(tenantId, serviceId, permissions);
    HttpResponse<HasPermissionResponse> response = client.hasPermission(hasPermissionRequest, token);
    // ... validation logic
}
```

**Proposed replacement using JWT claims:**

```java
// New: KeycloakSecurityService.java
@Singleton
public class KeycloakSecurityService {

    private final JwtTokenValidator tokenValidator;
    private final UserRepository userRepository;
    private final JurisdictionUserRepository jurisdictionUserRepository;

    public boolean isUserPermittedForTenantAction(Authentication authentication, Long tenantId, List<Permission> permissions) {
        // Extract roles from JWT claims (no HTTP call)
        List<String> userRoles = extractRolesFromClaims(authentication.getAttributes());

        // Check if user has any of the required permissions
        boolean hasPermission = permissions.stream()
            .map(Permission::getPermission)
            .anyMatch(userRoles::contains);

        // Apply tenant-level validation
        return hasPermission && validateTenantPermissions(userRoles);
    }

    private List<String> extractRolesFromClaims(Map<String, Object> claims) {
        // Keycloak stores roles in realm_access.roles or resource_access.{client}.roles
        Map<String, Object> realmAccess = (Map<String, Object>) claims.get("realm_access");
        if (realmAccess != null) {
            return (List<String>) realmAccess.get("roles");
        }
        return Collections.emptyList();
    }
}
```

#### 3.3.2 Update RequiresPermissionsAnnotationRule

```java
// Modified: RequiresPermissionsAnnotationRule.java
@Singleton
public class RequiresPermissionsAnnotationRule implements SecurityRule<HttpRequest<?>> {

    private final KeycloakSecurityService securityService;

    @Override
    public Publisher<SecurityRuleResult> check(HttpRequest<?> request, @Nullable Authentication authentication) {
        // ... existing route matching code ...

        // NEW: Use Authentication object instead of token string
        if (authentication == null) {
            return REJECTED;
        }

        return Mono.fromCallable(() -> {
            boolean result;
            if (jurisdictionId != null) {
                result = securityService.isUserPermittedForJurisdictionAction(
                    authentication, jurisdictionId, declaredPermissions);
            } else {
                result = securityService.isUserPermittedForTenantAction(
                    authentication, Long.valueOf(tenantId), declaredPermissions);
            }
            return result ? ALLOWED : REJECTED;
        }).subscribeOn(Schedulers.boundedElastic())
          .flatMapMany(ruleResult -> ruleResult);
    }
}
```

#### 3.3.3 Update application.yml

```yaml
# Current configuration
micronaut:
  http:
    services:
      auth:
        url: ${AUTH_BASE_URL}  # UnityAuth URL
  security:
    token:
      jwt:
        signatures:
          jwks:
            unity:
              url: ${AUTH_JWKS}  # UnityAuth JWKS
```

```yaml
# New Keycloak configuration
micronaut:
  security:
    token:
      jwt:
        signatures:
          jwks:
            keycloak:
              url: ${KEYCLOAK_JWKS_URL:`http://localhost:8180/realms/libre311/protocol/openid-connect/certs`}
    oauth2:
      clients:
        keycloak:
          client-id: ${KEYCLOAK_CLIENT_ID:`libre311-app`}
          client-secret: ${KEYCLOAK_CLIENT_SECRET}
          openid:
            issuer: ${KEYCLOAK_ISSUER:`http://localhost:8180/realms/libre311`}

# New config section
keycloak:
  realm: ${KEYCLOAK_REALM:`libre311`}
  auth-server-url: ${KEYCLOAK_URL:`http://localhost:8180`}
  resource: ${KEYCLOAK_CLIENT_ID:`libre311-app`}
```

### 3.4 Keycloak Realm Configuration

Create roles in Keycloak that match the current permission model:

```json
{
  "realm": "libre311",
  "roles": {
    "realm": [
      { "name": "LIBRE311_ADMIN_EDIT-SYSTEM" },
      { "name": "LIBRE311_ADMIN_VIEW-SYSTEM" },
      { "name": "LIBRE311_ADMIN_EDIT-TENANT" },
      { "name": "LIBRE311_ADMIN_VIEW-TENANT" },
      { "name": "LIBRE311_ADMIN_EDIT-SUBTENANT" },
      { "name": "LIBRE311_ADMIN_VIEW-SUBTENANT" },
      { "name": "LIBRE311_REQUEST_EDIT-SYSTEM" },
      { "name": "LIBRE311_REQUEST_VIEW-SYSTEM" },
      { "name": "LIBRE311_REQUEST_EDIT-TENANT" },
      { "name": "LIBRE311_REQUEST_VIEW-TENANT" },
      { "name": "LIBRE311_REQUEST_EDIT-SUBTENANT" },
      { "name": "LIBRE311_REQUEST_VIEW-SUBTENANT" }
    ]
  },
  "clients": [
    {
      "clientId": "libre311-app",
      "publicClient": true,
      "directAccessGrantsEnabled": true,
      "standardFlowEnabled": true
    }
  ]
}
```

### 3.5 Multi-Tenant Support

**Challenge:** UnityAuth validates permissions against specific `tenantId` values. Keycloak doesn't have native multi-tenant permission scoping.

**Solution Options:**

1. **Custom JWT Claims:** Add `tenantId` and `jurisdictionIds` as custom claims
   ```json
   {
     "sub": "user-uuid",
     "email": "user@example.com",
     "realm_access": { "roles": ["LIBRE311_ADMIN_EDIT-TENANT"] },
     "tenant_id": 1,
     "jurisdiction_ids": ["jurisdiction-1", "jurisdiction-2"]
   }
   ```

2. **Keycloak Groups:** Use groups to model tenant membership
   - Create groups: `/tenants/tenant-1`, `/tenants/tenant-2`
   - Assign users to groups
   - Map groups to roles

3. **Keep Local Database Validation:** Continue using `jurisdiction_user` table for jurisdiction-level access (current approach for SUBTENANT permissions)

---

## Part 4: Frontend Code Changes

### 4.1 Files Requiring Modification

| File | Change Type | Description |
|------|-------------|-------------|
| `frontend/src/lib/services/UnityAuth/UnityAuth.ts` | **Major Rewrite** | Replace with Keycloak adapter |
| `frontend/src/lib/services/UserPermissionsResolver.ts` | **Modify** | Parse Keycloak token claims |
| `frontend/src/lib/context/Libre311Context.ts` | **Modify** | Update auth service initialization |
| `frontend/src/routes/login/+page.svelte` | **Modify** | Update login flow |
| `frontend/.env.example` | **Modify** | Add Keycloak config variables |

### 4.2 Keycloak JavaScript Adapter Integration

**Option A: Use Official keycloak-js Adapter (Recommended)**

```typescript
// New: frontend/src/lib/services/KeycloakAuth/KeycloakAuth.ts
import Keycloak from 'keycloak-js';

export interface KeycloakAuthServiceProps {
  url: string;
  realm: string;
  clientId: string;
}

export class KeycloakAuthService {
  private keycloak: Keycloak;

  constructor(props: KeycloakAuthServiceProps) {
    this.keycloak = new Keycloak({
      url: props.url,
      realm: props.realm,
      clientId: props.clientId
    });
  }

  async init(): Promise<boolean> {
    return this.keycloak.init({
      onLoad: 'check-sso',
      checkLoginIframe: false
    });
  }

  login(): Promise<void> {
    return this.keycloak.login();
  }

  logout(): void {
    this.keycloak.logout();
  }

  getToken(): string | undefined {
    return this.keycloak.token;
  }

  getPermissions(): string[] {
    const roles = this.keycloak.realmAccess?.roles || [];
    return roles.filter(role => role.startsWith('LIBRE311_'));
  }

  isAuthenticated(): boolean {
    return !!this.keycloak.authenticated;
  }
}
```

**Option B: Keep Custom Implementation with Keycloak Endpoints**

```typescript
// Modified: frontend/src/lib/services/UnityAuth/UnityAuth.ts
// Rename to KeycloakAuth.ts

async login(email: string, password: string): Promise<CompleteLoginResponse> {
  // Use Keycloak token endpoint with Resource Owner Password Grant
  const params = new URLSearchParams();
  params.append('grant_type', 'password');
  params.append('client_id', this.clientId);
  params.append('username', email);
  params.append('password', password);

  const res = await this.axiosInstance.post(
    `/realms/${this.realm}/protocol/openid-connect/token`,
    params,
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );

  // Parse JWT to extract permissions (no backend call needed)
  const tokenPayload = this.parseJwt(res.data.access_token);
  const permissions = tokenPayload.realm_access?.roles?.filter(
    (r: string) => r.startsWith('LIBRE311_')
  ) || [];

  return {
    access_token: res.data.access_token,
    token_type: res.data.token_type,
    expires_in: res.data.expires_in,
    username: tokenPayload.preferred_username || tokenPayload.email,
    permissions
  };
}

private parseJwt(token: string): any {
  const base64Url = token.split('.')[1];
  const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
  return JSON.parse(atob(base64));
}
```

### 4.3 Login Page Changes

```svelte
<!-- Modified: frontend/src/routes/login/+page.svelte -->
<script lang="ts">
  // Option A: Redirect to Keycloak login page
  function handleLogin() {
    keycloakService.login(); // Redirects to Keycloak
  }

  // Option B: Keep form-based login (requires Direct Access Grants enabled)
  async function handleSubmit() {
    try {
      await keycloakService.login(email, password);
      goto('/issues/table');
    } catch (error) {
      errorMessage = 'Invalid credentials';
    }
  }
</script>
```

### 4.4 Environment Variables

```bash
# frontend/.env.example - New Keycloak variables
VITE_KEYCLOAK_URL=http://localhost:8180
VITE_KEYCLOAK_REALM=libre311
VITE_KEYCLOAK_CLIENT_ID=libre311-app
```

---

## Part 5: Test Updates

### 5.1 Backend Test Changes

| Test File | Changes Required |
|-----------|------------------|
| `MockUnityAuthClient.java` | Replace with `MockKeycloakTokenValidator` |
| `MockAuthenticationFetcher.java` | Update to provide Keycloak-style claims |
| `JurisdictionAdminControllerTest.java` | Update token/permission setup |
| `TenantAdminControllerTest.java` | Update token/permission setup |
| `RootControllerTest.java` | Update authentication mocks |

### 5.2 Mock Authentication Updates

```java
// New: MockKeycloakAuthentication.java
public class MockKeycloakAuthentication implements Authentication {

    private final String email;
    private final List<String> roles;

    public MockKeycloakAuthentication(String email, List<String> roles) {
        this.email = email;
        this.roles = roles;
    }

    @Override
    public Map<String, Object> getAttributes() {
        return Map.of(
            "sub", UUID.randomUUID().toString(),
            "email", email,
            "preferred_username", email,
            "realm_access", Map.of("roles", roles)
        );
    }

    @Override
    public String getName() {
        return email;
    }
}
```

---

## Part 6: Google Cloud Deployment

### 6.1 Deployment Options

| Option | Pros | Cons |
|--------|------|------|
| **GKE (Kubernetes)** | Full control, scalable, industry standard | More complex setup, higher operational overhead |
| **Cloud Run** | Serverless, auto-scaling, simpler | Limited customization, cold starts |
| **Compute Engine** | Full VM control | Manual scaling, more maintenance |

**Recommendation:** GKE for production, Cloud Run for development/staging.

### 6.2 Keycloak on GKE

#### 6.2.1 Architecture

```
                              ┌─────────────────────────────────────────┐
                              │           Google Cloud                   │
                              │                                          │
┌──────────┐                  │  ┌──────────────┐    ┌──────────────┐   │
│  Users   │──────────────────┼──│ Cloud Load   │────│     GKE      │   │
└──────────┘                  │  │  Balancer    │    │   Cluster    │   │
                              │  └──────────────┘    │              │   │
                              │                      │ ┌──────────┐ │   │
                              │                      │ │ Keycloak │ │   │
                              │                      │ │  Pods    │ │   │
                              │                      │ └────┬─────┘ │   │
                              │                      │      │       │   │
                              │                      │ ┌────▼─────┐ │   │
                              │  ┌──────────────┐    │ │ Libre311 │ │   │
                              │  │  Cloud SQL   │◀───┤ │   Pods   │ │   │
                              │  │  (PostgreSQL)│    │ └──────────┘ │   │
                              │  └──────────────┘    └──────────────┘   │
                              │                                          │
                              │  ┌──────────────┐                        │
                              │  │Cloud Storage │ (images)               │
                              │  └──────────────┘                        │
                              └─────────────────────────────────────────┘
```

#### 6.2.2 Keycloak Kubernetes Deployment

```yaml
# keycloak-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: libre311
spec:
  replicas: 2
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - name: keycloak
        image: quay.io/keycloak/keycloak:23.0
        args: ["start"]
        env:
        - name: KC_DB
          value: postgres
        - name: KC_DB_URL
          value: jdbc:postgresql://cloud-sql-proxy:5432/keycloak
        - name: KC_DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: keycloak-db-secret
              key: username
        - name: KC_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: keycloak-db-secret
              key: password
        - name: KC_HOSTNAME
          value: auth.your-domain.com
        - name: KC_PROXY
          value: edge
        - name: KC_HTTP_ENABLED
          value: "true"
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: libre311
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: keycloak
```

#### 6.2.3 Libre311 API Deployment

```yaml
# libre311-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: libre311-api
  namespace: libre311
spec:
  replicas: 3
  selector:
    matchLabels:
      app: libre311-api
  template:
    metadata:
      labels:
        app: libre311-api
    spec:
      serviceAccountName: libre311-sa
      containers:
      - name: libre311-api
        image: gcr.io/YOUR_PROJECT/libre311-api:latest
        env:
        - name: KEYCLOAK_JWKS_URL
          value: http://keycloak:8080/realms/libre311/protocol/openid-connect/certs
        - name: KEYCLOAK_ISSUER
          value: https://auth.your-domain.com/realms/libre311
        - name: LIBRE311_JDBC_URL
          value: jdbc:postgresql://cloud-sql-proxy:5432/libre311
        - name: GCP_PROJECT_ID
          valueFrom:
            configMapKeyRef:
              name: libre311-config
              key: gcp-project-id
        - name: STORAGE_BUCKET_ID
          valueFrom:
            configMapKeyRef:
              name: libre311-config
              key: storage-bucket
        ports:
        - containerPort: 8080
```

### 6.3 Cloud Run Alternative

```yaml
# cloudbuild.yaml for Cloud Run deployment
steps:
  # Build Keycloak image with realm config
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/keycloak:$SHORT_SHA', '-f', 'Dockerfile.keycloak', '.']

  # Build Libre311 API
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/libre311-api:$SHORT_SHA', '-f', 'DockerfileAPI', '.']

  # Deploy Keycloak to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'keycloak'
      - '--image=gcr.io/$PROJECT_ID/keycloak:$SHORT_SHA'
      - '--platform=managed'
      - '--region=us-central1'
      - '--add-cloudsql-instances=$PROJECT_ID:us-central1:keycloak-db'
      - '--set-env-vars=KC_DB=postgres,KC_PROXY=edge'

  # Deploy Libre311 API to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'libre311-api'
      - '--image=gcr.io/$PROJECT_ID/libre311-api:$SHORT_SHA'
      - '--platform=managed'
      - '--region=us-central1'
      - '--add-cloudsql-instances=$PROJECT_ID:us-central1:libre311-db'
```

### 6.4 Required GCP Services

| Service | Purpose | Estimated Cost |
|---------|---------|----------------|
| **GKE** | Container orchestration | $70-200/month (autopilot) |
| **Cloud SQL (PostgreSQL)** | Keycloak + Libre311 databases | $30-100/month |
| **Cloud Storage** | Image uploads | $0.02/GB/month |
| **Cloud Load Balancer** | HTTPS termination | $20/month |
| **Cloud DNS** | Domain management | $0.20/zone/month |
| **Secret Manager** | Credentials storage | $0.03/secret/month |
| **Cloud Armor** (optional) | WAF/DDoS protection | $5/policy/month |

### 6.5 Environment Variables for GCP

```bash
# Production environment variables
KEYCLOAK_URL=https://auth.your-domain.com
KEYCLOAK_REALM=libre311
KEYCLOAK_CLIENT_ID=libre311-app
KEYCLOAK_JWKS_URL=https://auth.your-domain.com/realms/libre311/protocol/openid-connect/certs
KEYCLOAK_ISSUER=https://auth.your-domain.com/realms/libre311

# Database (Cloud SQL)
LIBRE311_JDBC_URL=jdbc:postgresql:///libre311?cloudSqlInstance=PROJECT:REGION:INSTANCE&socketFactory=com.google.cloud.sql.postgres.SocketFactory
LIBRE311_JDBC_USER=libre311
LIBRE311_JDBC_PASSWORD=<from-secret-manager>

# GCP Services
GCP_PROJECT_ID=your-project-id
STORAGE_BUCKET_ID=your-bucket-name
```

### 6.6 Identity & Access Management

```yaml
# GKE Workload Identity setup
apiVersion: v1
kind: ServiceAccount
metadata:
  name: libre311-sa
  namespace: libre311
  annotations:
    iam.gke.io/gcp-service-account: libre311-sa@YOUR_PROJECT.iam.gserviceaccount.com
```

Required IAM roles:
- `roles/cloudsql.client` - Database access
- `roles/storage.objectAdmin` - Image uploads
- `roles/secretmanager.secretAccessor` - Read secrets

---

## Part 7: Migration Strategy

### 7.1 Phased Approach

**Phase 1: Parallel Setup (1-2 weeks)**
- Deploy Keycloak alongside UnityAuth
- Create realm and client configuration
- Migrate user accounts to Keycloak
- Test authentication flow

**Phase 2: Backend Migration (2-3 weeks)**
- Implement KeycloakSecurityService
- Update RequiresPermissionsAnnotationRule
- Update configuration files
- Update and run tests

**Phase 3: Frontend Migration (1-2 weeks)**
- Implement Keycloak adapter
- Update login flow
- Test end-to-end authentication

**Phase 4: Cutover & Cleanup (1 week)**
- Switch production to Keycloak
- Remove UnityAuth code and configuration
- Monitor for issues

### 7.2 Rollback Plan

1. Keep UnityAuth running during migration
2. Use feature flags to switch between auth providers
3. Maintain database compatibility (user table structure)
4. Document rollback procedure

### 7.3 Data Migration

**Users:** Export from UnityAuth, import to Keycloak
```bash
# Keycloak provides CLI for bulk user import
kcadm.sh create users -r libre311 -f users.json
```

**Permissions:** Map UnityAuth permissions to Keycloak roles
- Create realm roles matching permission names
- Assign roles to users based on UnityAuth data

---

## Part 8: Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Permission model mismatch | High | Medium | Thorough testing, parallel run |
| JWT claim structure differences | Medium | High | Custom claim mappers |
| Multi-tenant isolation breaks | High | Medium | Extensive testing per tenant |
| Performance degradation | Medium | Low | JWT caching, local validation |
| User migration data loss | High | Low | Backup, verification scripts |
| Frontend SSO issues | Medium | Medium | Test all browsers, clear cache |

---

## Conclusion

Migrating from UnityAuth to Keycloak is feasible but requires significant effort, primarily due to the custom permission-checking API that UnityAuth provides. The recommended approach is:

1. **Move permission validation to the backend** - Parse JWT claims locally instead of calling an external API
2. **Use Keycloak realm roles** - Map existing permissions to Keycloak roles
3. **Deploy on GKE** - Provides the best balance of control and scalability
4. **Follow phased migration** - Minimize risk with parallel operation period

The total effort is estimated at 4-6 weeks for a complete migration, with the backend permission system redesign being the most complex component.
