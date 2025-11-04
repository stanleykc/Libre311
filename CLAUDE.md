# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

Libre311 is an Open311-compliant service request application with three main components:

- **Backend API**: Micronaut-based Java 17 application (`app/` directory)
- **Frontend UI**: SvelteKit + TypeScript application (`frontend/` directory)
- **Database**: MySQL or PostgreSQL with Hibernate ORM and Flyway migrations

The system integrates with **UnityAuth** (https://github.com/UnityFoundation-io/UnityAuth) for authentication and authorization. UnityAuth must be running before starting Libre311.

### Key Domain Models

Located in `app/src/main/java/app/model/`:
- **Service**: Issue types (e.g., "Sidewalk", "Bus Stop")
- **ServiceDefinition**: Issue subtypes (e.g., "Cracked" for Sidewalk)
- **ServiceRequest**: User-reported issues linking Service + ServiceDefinition with contact and location data
- **User**: Authorized users in the `app_users` table

### Controllers

- `RootController.java`: Open311 GeoReport v2 API endpoints
- `JurisdictionAdminController.java`: Jurisdiction management
- `ImageStorageController.java`: Image upload handling
- `TenantAdminController.java`: Tenant administration

### External Dependencies

The API integrates with Google Cloud services:
- **Google Cloud Storage**: User-uploaded images
- **SafeSearch API**: Image content moderation
- **ReCaptcha**: Bot prevention
- **OAuth/Google Identity**: Admin authentication

Authentication uses Application Default Credentials (ADC). Set `ADC_PATH` for Docker environments.

## Development Commands

### Backend (Java/Micronaut)

```bash
# Run API server (from project root)
source setenv.sh
./gradlew app:run

# Run with auto-restart
./gradlew app:run -t

# Run tests
./gradlew app:test

# Build standalone JAR
./gradlew app:assemble
```

### Frontend (SvelteKit)

```bash
# Install dependencies
cd frontend
npm install

# Run dev server
npm run dev

# Build production
npm run build

# Preview production build
npm run preview

# Run all tests (integration + unit)
npm test

# Run unit tests only
npm run test:unit

# Run integration tests only (Playwright)
npm run test:integration

# Type checking
npm run check

# Linting
npm run lint

# Format code
npm run format
```

### Docker Environment

```bash
# Start all services
docker compose -f docker-compose.local.yml up

# Start specific service groups (via Makefile)
make compose_api   # API + Database
make compose_ui    # UI + Database
make compose_all   # All services

# Rebuild images after code changes
docker rmi <libre311-api-image-id>
docker rmi <libre311-ui-image-id>
# Then re-run docker compose up
```

### Service URLs (Docker)

- **API**: http://localhost:8080 (container: http://libre311-api:8080)
- **UI**: http://localhost:3000 (container: http://libre311-ui-dev:3000)
- **MySQL**: localhost:23306 (container: libre311-db:3306)

Add to `/etc/hosts` for consistent resolution:
```
127.0.0.1 libre311-api
127.0.0.1 libre311-db
127.0.0.1 libre311-ui
127.0.0.1 libre311-ui-dev
```

## Configuration

### Environment Setup

**Local development**:
1. Copy `setenv.sh.example` to `setenv.sh`
2. Update database and service URLs
3. Source before running: `source setenv.sh`

**Docker**:
1. Copy `.env.example` to `.env.docker`
2. Copy `frontend/.env.example` to `frontend/.env.docker`
3. Set `ADC_PATH` for GCP credentials

### Key Environment Variables

**API** (see `app/src/main/resources/application.yml`):
- `LIBRE311_JDBC_URL`, `LIBRE311_JDBC_DRIVER`, `LIBRE311_JDBC_USER`, `LIBRE311_JDBC_PASSWORD`
- `LIBRE311_AUTO_SCHEMA_GEN`: Database schema management (`update`, `create`, `validate`, etc.)
- `LIBRE311_DATABASE_DEPENDENCY`: Database driver(s) for Gradle (e.g., `mysql:mysql-connector-java:8.0.31`)
- `GCP_PROJECT_ID`, `STORAGE_BUCKET_ID`
- `RECAPTCHA_SECRET`
- `MICRONAUT_SECURITY_TOKEN_JWT_SIGNATURES_SECRET_GENERATOR_SECRET`
- `MICRONAUT_SECURITY_TOKEN_JWT_GENERATOR_REFRESH_TOKEN_SECRET`
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`

**Frontend**:
- `VITE_BACKEND_URL`: API base URL (use `/api` if served by API, otherwise API's actual URL)

## Important Patterns

### Data Transfer Objects (DTOs)

All HTTP request/response bodies use DTOs in `app/src/main/java/app/dto/` with field-level validation annotations. Validation happens automatically when DTOs are annotated with `@Valid @Body`.

### Repository Layer

Data repositories extend Micronaut Data interfaces in `app/src/main/java/app/model/` subdirectories.

### Service Layer

Service classes in `app/src/main/java/app/service/` handle business logic and inject repositories and other services.

### Frontend Structure

- `frontend/src/lib/components/`: Reusable Svelte components
- `frontend/src/lib/services/`: API clients and business logic
- `frontend/src/lib/context/`: Svelte stores and context
- `frontend/src/routes/`: SvelteKit file-based routing
- Uses TailwindCSS and STWUI component library

### CSV Downloads

Users authorized for CSV downloads must be added to `app_users` table:
```sql
USE libre311db;
INSERT INTO app_users (email) VALUES ('user@example.com');
```

## Testing

- **Backend tests**: `app/src/test/java/app/*ControllerTest.java`
- **Frontend unit tests**: Vitest (`.test.ts` files)
- **Frontend integration tests**: Playwright in `frontend/tests/`

Run frontend tests with `NODE_ENV=test` to ensure proper test environment.

## Active Technologies
- Python 3.11+ (Robot Framework 7.3.2 requires Python 3.8+, using 3.11 for modern features) + Robot Framework 7.3.2, robotframework-browser 19.10.0 (Playwright-based), RESTinstance 1.5.2 (API testing with OpenAPI validation), robotframework-databaselibrary 2.0.4 + pymysql 1.1.0, robotframework-faker 5.0.0 + Faker 30.8.2, robotframework-dockerlibrary (container management) (001-citizen-acceptance-tests)
- Docker MySQL container (libre311-db:3306) accessed via test setup scripts for data seeding and cleanup (001-citizen-acceptance-tests)

## Recent Changes
- 001-citizen-acceptance-tests: Added Python 3.11+ (Robot Framework 7.3.2 requires Python 3.8+, using 3.11 for modern features) + Robot Framework 7.3.2, robotframework-browser 19.10.0 (Playwright-based), RESTinstance 1.5.2 (API testing with OpenAPI validation), robotframework-databaselibrary 2.0.4 + pymysql 1.1.0, robotframework-faker 5.0.0 + Faker 30.8.2, robotframework-dockerlibrary (container management)
