# UnityAuth to Google Identity Platform Migration Evaluation

## Executive Summary

This document evaluates the feasibility and requirements for replacing UnityAuth with Google Identity Platform in Libre311. The migration involves changes to both the backend (Micronaut/Java) and frontend (SvelteKit/TypeScript), as well as significant Google Cloud configuration.

**Complexity Assessment: Medium-High**

The migration is achievable but requires careful planning due to:
- Custom permission system that must be re-implemented
- Multi-tenant architecture considerations
- User-Jurisdiction association logic currently handled by UnityAuth

---

## 1. Current UnityAuth Architecture

### 1.1 Overview

UnityAuth is an external OAuth/JWT authentication service that provides:
- User authentication (username/password login)
- JWT token issuance with JWKS validation
- Permission management (tenant/service-based)
- Multi-tenant support

### 1.2 Key Integration Points

#### Backend Files (Java/Micronaut)

| File | Purpose |
|------|---------|
| `app/src/main/java/app/security/UnityAuthClient.java` | HTTP client interface for UnityAuth API calls |
| `app/src/main/java/app/security/UnityAuthService.java` | Permission validation and user lookup logic |
| `app/src/main/java/app/security/RequiresPermissionsAnnotationRule.java` | Security rule implementing `@RequiresPermissions` |
| `app/src/main/java/app/security/RequiresPermissions.java` | Custom annotation for method-level authorization |
| `app/src/main/java/app/security/Permission.java` | Enum of all permission types |
| `app/src/main/java/app/security/JurisdictionValidationFilter.java` | Request filter for jurisdiction validation |
| `app/src/main/java/app/PermissionsController.java` | Endpoint to fetch user permissions |

#### Frontend Files (TypeScript/Svelte)

| File | Purpose |
|------|---------|
| `frontend/src/lib/services/UnityAuth/UnityAuth.ts` | Auth service (login, logout, token storage) |
| `frontend/src/lib/services/UserPermissionsResolver.ts` | Fetches user permissions from backend |
| `frontend/src/lib/components/AuthGuard.svelte` | Permission-based component visibility |
| `frontend/src/lib/context/Libre311Context.ts` | Auth context and event subscription |
| `frontend/src/routes/login/+page.svelte` | Login page |

### 1.3 UnityAuth API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/login` | POST | Authenticate user, returns JWT |
| `/api/hasPermission` | POST | Check if user has specific permissions |
| `/api/principal/permissions` | POST | Get all user permissions for a tenant/service |
| `/keys` | GET | JWKS endpoint for JWT signature validation |

### 1.4 Permission Model

Libre311 uses a hierarchical permission system:

```
LIBRE311_{CATEGORY}_{ACTION}-{SCOPE}

Categories: ADMIN, REQUEST
Actions: EDIT, VIEW
Scopes: SYSTEM, TENANT, SUBTENANT
```

**Examples:**
- `LIBRE311_ADMIN_EDIT-SYSTEM` - System-wide admin edit access
- `LIBRE311_REQUEST_VIEW-TENANT` - Tenant-level request viewing
- `LIBRE311_ADMIN_VIEW-SUBTENANT` - Subtenant admin view access

### 1.5 Authorization Flow

```
┌─────────┐    ┌──────────────┐    ┌───────────┐    ┌──────────┐
│ Frontend│───>│ POST /login  │───>│ UnityAuth │───>│ JWT Token│
└─────────┘    └──────────────┘    └───────────┘    └──────────┘
                                                          │
                                                          ▼
┌─────────┐    ┌──────────────┐    ┌───────────┐    ┌──────────┐
│ Frontend│───>│ API Request  │───>│  Backend  │───>│ JWKS     │
│         │    │ + Bearer     │    │ validates │    │validation│
└─────────┘    └──────────────┘    └───────────┘    └──────────┘
                                         │
                                         ▼
                                   ┌───────────┐
                                   │ UnityAuth │
                                   │ hasPermis │
                                   └───────────┘
```

---

## 2. Google Identity Platform Capabilities

### 2.1 What Google Identity Platform Offers

Google Identity Platform (GIP) is a customer identity and access management (CIAM) solution:

| Feature | Description |
|---------|-------------|
| **Multi-provider Auth** | Google, email/password, phone, SAML, OIDC, anonymous |
| **JWT Tokens** | Firebase Auth JWTs or custom tokens |
| **JWKS Endpoint** | Standard JWKS for token validation |
| **Custom Claims** | Add custom data to JWT tokens |
| **Multi-tenancy** | Tenant isolation for B2B scenarios |
| **Admin SDK** | Server-side user management |
| **Client SDKs** | Web, iOS, Android, Flutter |

### 2.2 Key Differences from UnityAuth

| Aspect | UnityAuth | Google Identity Platform |
|--------|-----------|--------------------------|
| **Permission Storage** | UnityAuth database | Custom claims in JWT or external database |
| **Multi-tenancy** | Built-in tenant/service model | Multi-tenancy add-on (separate config) |
| **User Management** | UnityAuth admin | Firebase Console or Admin SDK |
| **Permission Check API** | `/hasPermission` endpoint | Custom implementation required |
| **JWKS URL** | `{AUTH_BASE_URL}/keys` | `https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com` |

---

## 3. Code Changes Required

### 3.1 Backend Changes

#### 3.1.1 Configuration (`application.yml`)

**Current:**
```yaml
micronaut:
  http:
    services:
      auth:
        url: ${AUTH_BASE_URL}
  security:
    token:
      jwt:
        signatures:
          jwks:
            unity:
              url: ${AUTH_JWKS}
```

**New:**
```yaml
micronaut:
  security:
    token:
      jwt:
        signatures:
          jwks:
            google:
              url: https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
        # Or use Firebase public keys
        signatures:
          jwks:
            firebase:
              url: https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com

firebase:
  project-id: ${GCP_PROJECT_ID}
```

#### 3.1.2 New Service: GoogleIdentityService

Replace `UnityAuthService.java` with a new service:

```java
@Singleton
public class GoogleIdentityService {

    private final FirebaseAuth firebaseAuth;
    private final UserRepository userRepository;
    private final JurisdictionRepository jurisdictionRepository;
    private final JurisdictionUserRepository jurisdictionUserRepository;

    // Initialize Firebase Admin SDK
    @PostConstruct
    void init() {
        FirebaseApp.initializeApp(FirebaseOptions.builder()
            .setCredentials(GoogleCredentials.getApplicationDefault())
            .setProjectId(projectId)
            .build());
    }

    public List<String> getUserPermissions(String uid, String jurisdictionId) {
        // Option 1: Read from custom claims in token
        // Option 2: Read from Firestore/database
        // Option 3: Compute based on JurisdictionUser table
    }

    public boolean hasPermission(String uid, String jurisdictionId, List<Permission> permissions) {
        // Implement permission checking logic
    }
}
```

#### 3.1.3 Replace UnityAuthClient

**Delete:** `UnityAuthClient.java`

**Reason:** No longer need HTTP client to external auth service. Firebase Admin SDK handles this.

#### 3.1.4 Modify RequiresPermissionsAnnotationRule

Update to extract user ID from Firebase JWT and use new permission service:

```java
@Singleton
public class RequiresPermissionsAnnotationRule implements SecurityRule<HttpRequest<?>> {

    private final GoogleIdentityService identityService;

    @Override
    public SecurityRuleResult check(HttpRequest<?> request, Authentication authentication) {
        // Extract Firebase UID from authentication
        String uid = (String) authentication.getAttributes().get("uid");

        // Get permissions using new service
        boolean permitted = identityService.hasPermission(
            uid,
            jurisdictionId,
            requiredPermissions
        );

        return permitted ? ALLOWED : REJECTED;
    }
}
```

#### 3.1.5 Permission Storage Strategy

Since Google Identity Platform doesn't have a built-in permission API like UnityAuth, you need to choose a storage strategy:

**Option A: Custom Claims in JWT (Recommended for <1000 bytes)**
```java
// Set custom claims via Admin SDK
Map<String, Object> claims = new HashMap<>();
claims.put("permissions", Arrays.asList("LIBRE311_ADMIN_EDIT-SYSTEM"));
claims.put("tenantId", 12345L);
FirebaseAuth.getInstance().setCustomUserClaims(uid, claims);
```

**Option B: Firestore Database**
```
/users/{uid}/permissions
  - jurisdictionId: "city.gov"
  - permissions: ["LIBRE311_ADMIN_EDIT-SUBTENANT", ...]
```

**Option C: Existing MySQL Database (Simplest)**
Keep existing `JurisdictionUser` table and add a permissions column or separate permissions table.

#### 3.1.6 New Dependencies (build.gradle)

```gradle
// Firebase Admin SDK
implementation 'com.google.firebase:firebase-admin:9.2.0'

// If using Firestore
implementation 'com.google.cloud:google-cloud-firestore:3.15.0'
```

### 3.2 Frontend Changes

#### 3.2.1 Replace UnityAuth Service

**File:** `frontend/src/lib/services/UnityAuth/UnityAuth.ts`

Replace with Firebase/Google Identity SDK:

```typescript
import { initializeApp } from 'firebase/app';
import {
  getAuth,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  type User
} from 'firebase/auth';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

export class GoogleAuthServiceImpl implements AuthService {

  async login(email: string, password: string): Promise<CompleteLoginResponse> {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const token = await userCredential.user.getIdToken();

    // Fetch permissions from backend
    const permissions = await this.fetchPermissions(token);

    return {
      access_token: token,
      username: userCredential.user.email,
      permissions
    };
  }

  logout(): void {
    signOut(auth);
    sessionStorage.removeItem('loginData');
  }

  onAuthStateChanged(callback: (user: User | null) => void) {
    return onAuthStateChanged(auth, callback);
  }

  async getIdToken(): Promise<string | null> {
    return auth.currentUser?.getIdToken() ?? null;
  }
}
```

#### 3.2.2 Token Refresh Handling

Firebase handles token refresh automatically, but you need to update the interceptor:

```typescript
// Libre311.ts - Update auth interceptor
setAuthInfo(authService: AuthService): void {
  this.axiosInstance.interceptors.request.use(async (config) => {
    const token = await authService.getIdToken();
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  });
}
```

#### 3.2.3 New Dependencies (package.json)

```json
{
  "dependencies": {
    "firebase": "^10.7.0"
  }
}
```

#### 3.2.4 Environment Variables

**New:**
```env
VITE_FIREBASE_API_KEY=your-api-key
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
```

---

## 4. Google Cloud Setup Requirements

### 4.1 Enable Required APIs

```bash
gcloud services enable identitytoolkit.googleapis.com
gcloud services enable firebaseauth.googleapis.com
gcloud services enable firestore.googleapis.com  # If using Firestore for permissions
```

### 4.2 Identity Platform Configuration

1. **Navigate to:** Google Cloud Console > Identity Platform
2. **Enable Identity Platform** for the project
3. **Add Sign-in Providers:**
   - Email/Password (required)
   - Google (optional)
   - Other providers as needed

### 4.3 Configure Authentication Settings

**In Firebase Console or Identity Platform:**

| Setting | Value |
|---------|-------|
| Authorized domains | `localhost`, your production domains |
| Email enumeration protection | Enabled (recommended) |
| Password policy | Minimum 8 characters, require complexity |

### 4.4 Service Account Setup

For backend Admin SDK access:

```bash
# Create service account
gcloud iam service-accounts create libre311-auth \
  --display-name="Libre311 Auth Service"

# Grant Firebase Admin role
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:libre311-auth@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/firebaseauth.admin"

# Download credentials
gcloud iam service-accounts keys create firebase-admin-key.json \
  --iam-account=libre311-auth@${PROJECT_ID}.iam.gserviceaccount.com
```

### 4.5 Multi-tenancy Setup (If Required)

If you need tenant isolation (separate user pools per tenant):

1. Enable multi-tenancy in Identity Platform settings
2. Create tenants via Console or API:
   ```bash
   gcloud identity-platform tenants create \
     --display-name="Tenant A"
   ```
3. Update backend to use tenant-specific Firebase instances

### 4.6 Firestore Setup (If Using for Permissions)

```bash
gcloud firestore databases create --location=us-central1
```

**Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/permissions/{jurisdictionId} {
      allow read: if request.auth.uid == userId;
      allow write: if false; // Admin SDK only
    }
  }
}
```

---

## 5. Migration Approach

### 5.1 Recommended Phases

#### Phase 1: Backend Preparation (1-2 weeks effort)
1. Add Firebase Admin SDK dependency
2. Create `GoogleIdentityService` alongside existing `UnityAuthService`
3. Implement permission storage strategy
4. Add feature flag to switch between auth providers

#### Phase 2: Frontend Migration (1 week effort)
1. Add Firebase SDK
2. Create new auth service implementation
3. Update context and interceptors
4. Add feature flag support

#### Phase 3: Permission Data Migration
1. Export permissions from UnityAuth
2. Import into chosen storage (custom claims, Firestore, or MySQL)
3. Map existing users to Firebase UIDs

#### Phase 4: Testing & Validation (1 week effort)
1. Test all protected endpoints
2. Verify permission inheritance logic
3. Test multi-jurisdiction scenarios
4. Test token refresh behavior

#### Phase 5: Cutover
1. Remove UnityAuth service dependency
2. Update environment configuration
3. Remove deprecated code

### 5.2 Feature Flag Implementation

```yaml
# application.yml
auth:
  provider: ${AUTH_PROVIDER:unityauth}  # unityauth | google
```

```java
@Factory
public class AuthProviderFactory {
    @Singleton
    @Requires(property = "auth.provider", value = "google")
    public AuthService googleAuthService(GoogleIdentityService service) {
        return service;
    }

    @Singleton
    @Requires(property = "auth.provider", value = "unityauth")
    public AuthService unityAuthService(UnityAuthService service) {
        return service;
    }
}
```

---

## 6. Key Challenges & Considerations

### 6.1 Permission System Gap

**Challenge:** Google Identity Platform has no equivalent to UnityAuth's `/hasPermission` API.

**Solution:** Implement permission checking in Libre311 backend:
- Store permissions in custom claims (limited to 1000 bytes)
- Store in Firestore with Admin SDK access
- Store in existing MySQL database

### 6.2 Service ID Concept

**Challenge:** UnityAuth uses `serviceId` to scope permissions. GIP doesn't have this concept.

**Solution:**
- Embed service context in custom claims
- Or validate at application level using JurisdictionUser table

### 6.3 Token Size Limits

**Challenge:** Firebase custom claims are limited to 1000 bytes.

**Impact:** Users with many permissions may exceed the limit.

**Solution:** Store permissions externally and fetch on each request, or use permission groups.

### 6.4 User Migration

**Challenge:** Existing users in UnityAuth need accounts in Google Identity Platform.

**Solutions:**
1. **Bulk Import:** Use Firebase Admin SDK's `importUsers()`
2. **Password Hash Migration:** Firebase supports bcrypt, scrypt, PBKDF2
3. **First-Login Migration:** Prompt users to re-authenticate

### 6.5 Cost Considerations

| Service | Free Tier | Paid Tier |
|---------|-----------|-----------|
| Identity Platform | 50K MAU | $0.0055/MAU after |
| Firestore | 1GB storage, 50K reads/day | Pay per operation |
| Cloud Functions (if used) | 2M invocations/month | $0.40/million |

---

## 7. Files Requiring Changes

### 7.1 Backend (app/)

| File | Change Type | Effort |
|------|-------------|--------|
| `build.gradle` | Add Firebase dependencies | Low |
| `application.yml` | New Firebase config | Low |
| `application-*.yml` | Environment-specific config | Low |
| `UnityAuthClient.java` | Delete or deprecate | Low |
| `UnityAuthService.java` | Replace with GoogleIdentityService | High |
| `RequiresPermissionsAnnotationRule.java` | Update token extraction | Medium |
| `PermissionsController.java` | Update to use new service | Medium |
| `MockUnityAuthClient.java` | Update for testing | Medium |
| New: `GoogleIdentityService.java` | Create new service | High |
| New: `FirebaseConfig.java` | Firebase initialization | Medium |

### 7.2 Frontend (frontend/)

| File | Change Type | Effort |
|------|-------------|--------|
| `package.json` | Add Firebase dependency | Low |
| `.env.example` | Add Firebase config vars | Low |
| `UnityAuth.ts` | Replace with Firebase impl | High |
| `UserPermissionsResolver.ts` | Update for new token format | Medium |
| `Libre311Context.ts` | Update auth subscription | Medium |
| `Libre311.ts` | Update token interceptor | Medium |
| `login/+page.svelte` | Use new auth service | Low |

### 7.3 Configuration & Infrastructure

| File | Change Type |
|------|-------------|
| `.env.example` | Add Firebase/GCP variables |
| `docker-compose.*.yml` | Update environment variables |
| `README.md` | Update setup documentation |
| New: `docs/google-identity-setup.md` | Setup guide |

---

## 8. Summary

### 8.1 Effort Estimate

| Area | Estimated Effort |
|------|------------------|
| Backend code changes | 2-3 weeks |
| Frontend code changes | 1 week |
| Google Cloud setup | 2-3 days |
| Testing & validation | 1 week |
| Documentation | 2-3 days |
| **Total** | **5-6 weeks** |

### 8.2 Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Permission system complexity | High | High | Thorough design before implementation |
| User migration issues | Medium | High | Test with subset of users first |
| Token size limitations | Low | Medium | Use external permission storage |
| Cost overruns | Low | Low | Monitor usage, implement caching |

### 8.3 Recommendation

The migration is **feasible and recommended** if:
1. You want to reduce external dependencies (no separate UnityAuth service)
2. You need better integration with other GCP services
3. You want Firebase's mature client SDKs and auth UI options

**Not recommended** if:
1. UnityAuth is shared with other services in your organization
2. The permission model is highly dynamic and exceeds JWT size limits
3. Migration timeline is shorter than 4-5 weeks
