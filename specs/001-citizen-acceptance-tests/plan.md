# Implementation Plan: Citizen Acceptance Test Suite

**Branch**: `001-citizen-acceptance-tests` | **Date**: 2025-11-04 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-citizen-acceptance-tests/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Create a comprehensive Robot Framework acceptance test suite covering all citizen use cases for the Libre311 Open311-compliant service request application. Tests will validate end-to-end user journeys across the 3-tier architecture (SvelteKit UI, Micronaut API, MySQL/PostgreSQL database) running in Docker containers. The test suite will be organized into three priority levels (P1: browse/view, P2: submit/track, P3: authenticated workflows) with focus on Open311 API compliance validation, realistic test data, environment parity with production, and observable test execution with comprehensive diagnostics.

## Technical Context

**Language/Version**: Python 3.11+ (Robot Framework 7.3.2 requires Python 3.8+, using 3.11 for modern features)
**Primary Dependencies**: Robot Framework 7.3.2, robotframework-browser 19.10.0 (Playwright-based), RESTinstance 1.5.2 (API testing with OpenAPI validation), robotframework-databaselibrary 2.0.4 + pymysql 1.1.0, robotframework-faker 5.0.0 + Faker 30.8.2, robotframework-dockerlibrary (container management)
**Storage**: Docker MySQL container (libre311-db:3306) accessed via test setup scripts for data seeding and cleanup
**Testing**: Robot Framework with Browser Library (Playwright for UI), RESTinstance (REST API with Open311 compliance), DatabaseLibrary (MySQL data management), DockerLibrary (container health checks), FakerLibrary (realistic test data)
**Target Platform**: Docker Desktop on macOS/Linux/Windows for local execution; Linux containers for CI/CD
**Project Type**: Test suite (acceptance testing infrastructure)
**Performance Goals**: P1 test suite < 5 minutes execution, P2 < 10 minutes, P3 < 15 minutes; 95% of individual test scenarios < 10 seconds
**Constraints**: Tests must run against Docker environment (libre311-api:8080, libre311-ui-dev:3000, libre311-db:3306 on unity-network); no external service dependencies except mocked external APIs
**Scale/Scope**: 5 user stories, 32 acceptance scenarios, 12 edge cases; estimated 50-75 test cases total across P1/P2/P3 suites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Review each principle from `.specify/memory/constitution.md` and verify compliance:

- **Principle I (E2E User Journey Testing)**: Tests must validate complete UI → API → Database flows without mocking internal boundaries. External services (UnityAuth, GCP) may be mocked.
- **Principle II (Test Isolation)**: Each test suite must be independently executable with its own data cleanup or isolated database schema.
- **Principle III (Open311 Compliance)**: All Open311 API tests must validate against the actual GeoReport v2 specification.
- **Principle IV (Realistic Test Data)**: Use real-world addresses, coordinates, and service request data—avoid placeholder values.
- **Principle V (Environment Parity)**: Tests must run against Docker-composed environments matching production topology (libre311-api, libre311-ui-dev, libre311-db on unity-network).
- **Principle VI (Observable Execution)**: Test failures must produce screenshots, API logs, database dumps, and container logs for debugging. Use library-specific patterns for diagnostic capture (RESTinstance via $rest.instances[-1], conditional Browser Library screenshots).
- **Principle VII (API Testing Standards)**: API tests must document full endpoint paths with base URL prefixes, required parameters, response parsing patterns, and environment variables. Use documented library access patterns to avoid trial-and-error debugging.
- **Principle VIII (Test Data Type Handling)**: Tests must handle data type validation appropriately with type-specific Robot Framework keywords. Verify field existence before type validation, use correct keywords for string/numeric/boolean/array fields.

**Test Organization Compliance**:
- Suites organized by priority (P1/P2/P3) in separate .robot files
- Proper tagging strategy (priority, component, feature, type)
- Keywords follow verb-noun naming convention
- Test data uses variables, not hardcoded values

**Quality Gates Compliance**:
- P1 tests run on every PR (must complete in <15 minutes)
- Coverage includes all Open311 endpoints and core UI workflows
- Pre-commit checks verify tests pass locally against Docker environment

If any principle cannot be followed, document the violation in the Complexity Tracking table below.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
tests/acceptance/                    # New acceptance test suite (to be created)
├── suites/
│   ├── P1_browse_services.robot    # User Story 1: Browse Available Services
│   ├── P1_view_requests.robot      # User Story 2: View Existing Service Requests
│   ├── P2_submit_anonymous.robot   # User Story 3: Submit Request Without Account
│   ├── P2_track_request.robot      # User Story 4: Track Service Request Status
│   └── P3_submit_authenticated.robot # User Story 5: Submit Request With Account
├── resources/
│   ├── keywords/
│   │   ├── ui_keywords.robot       # Browser interaction keywords
│   │   ├── api_keywords.robot      # REST API interaction keywords
│   │   └── db_keywords.robot       # Database setup/teardown keywords
│   ├── libraries/
│   │   ├── Open311Validator.py     # Custom Python library for Open311 compliance
│   │   └── TestDataGenerator.py    # Realistic test data generation
│   └── variables/
│       ├── environments.robot      # Environment configs (URLs, credentials)
│       └── test_data.robot         # Static test data (addresses, service types)
├── setup/
│   ├── docker-compose.test.yml     # Test-specific Docker config (if needed)
│   └── seed_test_data.py           # Database seeding script
└── reports/                         # Test execution reports (gitignored)

# Existing Libre311 structure (unchanged)
app/                                 # Backend API (Micronaut/Java)
frontend/                            # UI (SvelteKit/TypeScript)
docker-compose.local.yml             # Development Docker config
```

**Structure Decision**: This is an acceptance test suite being added to an existing web application. The test infrastructure is independent and isolated in `tests/acceptance/` to avoid interfering with existing unit and integration tests. The structure follows the constitution's required directory layout with suites organized by priority (P1/P2/P3), reusable keywords in resources, and custom libraries for Open311 validation.

## Constitution Check Evaluation

**Status**: ✅ PASSED - All principles compliant, no violations

- **Principle I (E2E Testing)**: ✅ Tests will validate UI → API → Database without mocking internal boundaries. External services (UnityAuth, GCP, OAuth) will be mocked per constitution allowance.
- **Principle II (Test Isolation)**: ✅ Each test suite independently executable with database cleanup/seeding per suite.
- **Principle III (Open311 Compliance)**: ✅ Custom Open311Validator.py library will validate against GeoReport v2 specification.
- **Principle IV (Realistic Test Data)**: ✅ TestDataGenerator.py will create realistic addresses, coordinates, and descriptions.
- **Principle V (Environment Parity)**: ✅ Tests run against docker-compose.local.yml matching production topology.
- **Principle VI (Observable Execution)**: ✅ Robot Framework native screenshot capture, plus custom logging for API/DB diagnostics. RESTinstance response context via $rest.instances[-1], conditional Browser Library screenshots based on test tags.
- **Principle VII (API Testing Standards)**: ✅ environments.robot documents API_BASE_URL with full path prefix (/api), api_keywords.robot uses documented RESTinstance access patterns, JURISDICTION_ID documented as required parameter.
- **Principle VIII (Test Data Type Handling)**: ✅ api_keywords.robot uses Dictionary Should Contain Key before field access, type-appropriate validation (Should Not Be Empty for strings, type checks for numeric/boolean fields).
- **Test Organization**: ✅ Suites organized by P1/P2/P3 with proper tagging and verb-noun keyword naming.
- **Quality Gates**: ✅ P1 suite designed for <5 minute execution per performance goals.

**Re-evaluation after Phase 1**: ✅ PASSED

Phase 1 design artifacts confirm constitution compliance:
- **Open311Validator.py** design specified in contracts/ and data-model.md
- **TestDataGenerator.py** design specified using robotframework-faker for realistic data
- **RESTinstance** selected for native Open311 OpenAPI schema validation
- **Browser Library** network interception enables external service mocking
- **DatabaseLibrary** transaction support enables proper test isolation
- All design decisions align with constitution principles

**Final Status**: Ready for Phase 2 (tasks.md generation via /speckit.tasks)

## Complexity Tracking

No violations - table not needed.
