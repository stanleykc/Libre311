<!--
Sync Impact Report:
Version: 1.0.0 → 1.1.0
Change Type: MINOR (New principles added, existing principles clarified)
Modified Principles:
  - Principle VI: Enhanced with API/library-specific diagnostic requirements
Added Sections:
  - Principle VII: API Testing Standards (new)
  - Principle VIII: Test Data Type Handling (new)
  - Enhanced Test Organization Standards with library usage patterns
Templates Requiring Updates:
  ✅ plan-template.md - Constitution Check section updated to reference Principles VII and VIII
  ⚠ tasks-template.md - Should add guidance for API test tasks following Principle VII standards
  ⚠ quickstart.md - Should document environment variables and API endpoint patterns
Follow-up TODOs:
  - Document RESTinstance response access patterns in test library documentation
  - Create troubleshooting guide for common test failures (data type validation, API auth)
-->

# Libre311 Robot Framework Acceptance Testing Constitution

## Core Principles

### I. End-to-End User Journey Testing (NON-NEGOTIABLE)

All acceptance tests MUST validate complete user journeys across the 3-tier architecture (Frontend → API → Database). Tests MUST NOT mock external boundaries between UI, API, or database layers. Integration points with external services (UnityAuth, Google Cloud Storage, SafeSearch, ReCaptcha) MAY use test doubles when necessary for test reliability and speed.

**Rationale**: The primary value of acceptance testing is validating that all tiers work together correctly. Mocking internal boundaries defeats this purpose and creates false confidence. External service mocking is acceptable because these dependencies are outside our control and can introduce flakiness.

### II. Test Isolation and Idempotency

Each test suite MUST be independently executable and produce identical results regardless of execution order. Tests MUST clean up all data they create or use isolated test databases/schemas per suite. No test MAY depend on state created by another test.

**Rationale**: Parallel test execution, selective test runs, and debugging individual failures all require tests to be completely independent. Shared state creates cascading failures and makes test maintenance nearly impossible.

### III. Open311 Compliance Validation

All tests covering Open311 GeoReport v2 API endpoints MUST validate compliance with the Open311 specification. This includes validating request/response formats, required fields, error codes, and service discovery endpoints. Tests MUST use the actual Open311 specification as the source of truth.

**Rationale**: Libre311's core value proposition is Open311 compliance. Acceptance tests must prove this compliance rather than testing arbitrary custom behavior that may drift from the standard.

### IV. Realistic Test Data

Test data MUST reflect real-world usage patterns including valid addresses, geographic coordinates within jurisdiction boundaries, realistic service request descriptions, and valid image uploads. Avoid placeholder values like "test@test.com" or "123 Main St" unless testing validation logic.

**Rationale**: Unrealistic test data masks integration issues (e.g., geocoding failures, image processing errors, validation edge cases) that only surface in production. Tests should stress the system as real users would.

### V. Environment Parity

Tests MUST run against Docker-composed environments that mirror production configuration (libre311-api, libre311-ui-dev, libre311-db containers on unity-network). Database schema MUST be managed via Flyway migrations, not manual setup scripts. Environment configuration MUST use `.env.docker` files, not hardcoded values.

**Rationale**: Configuration drift between test and production environments is a primary source of production defects. Testing against the actual deployment topology catches issues that unit or integration tests miss.

### VI. Observable Test Execution

Test failures MUST produce actionable diagnostics including screenshots (for UI tests), API request/response logs, database state dumps, and container logs. Test reports MUST clearly identify which tier (UI/API/DB) failed and why. Browser console errors MUST be captured and reported.

**Test Type-Specific Requirements**:
- **UI Tests**: MUST capture screenshots on failure, browser console logs, and DOM state
- **API Tests**: MUST log full request (method, URL, headers, body) and response (status, headers, body) on failure
- **Database Tests**: MUST log query execution plans and result sets on assertion failures
- **Mixed Tests**: MUST conditionally capture diagnostics based on test tags (e.g., only screenshot if `ui` tag present)

**Library-Specific Guidance**:
- RESTinstance: Use `$rest.instances[-1]` to access last response context with full request/response details
- Browser Library: Use conditional screenshot capture checking if browser context exists before attempting capture
- DatabaseLibrary: Log full query text and parameter bindings on query failures

**Rationale**: Acceptance test failures in CI/CD pipelines are expensive to debug. Rich diagnostic output reduces mean-time-to-resolution and prevents "works on my machine" issues. Different test types require different diagnostic approaches.

### VII. API Testing Standards (NEW)

API tests MUST validate against the actual API implementation, not assumptions. All API tests MUST:

1. **Endpoint Discovery**: Document full endpoint paths including base URL prefixes (e.g., `/api/services` not `/services`)
2. **Required Parameters**: Explicitly test and document all required query parameters (e.g., `jurisdiction_id`)
3. **Response Parsing**: Use documented library patterns for accessing response data (avoid trial-and-error access patterns)
4. **Environment Variables**: Define all API-related environment variables in `environments.robot` with clear descriptions:
   - `API_BASE_URL`: Full base URL including path prefix
   - `JURISDICTION_ID`: Default jurisdiction for test data
   - Any API authentication tokens or keys required

5. **Library Usage Patterns**: Document standard patterns for each testing library:
   - RESTinstance response access: `${rest} = Get Library Instance REST`, then `${ctx} = Evaluate $rest.instances[-1]`
   - HTTP status validation: Always verify status code before accessing response body
   - Error handling: Test MUST handle and log API errors gracefully, not crash on unexpected response formats

**Rationale**: During T024 implementation, multiple trial-and-error cycles were required to discover correct API paths, required parameters, and library access patterns. These should be discoverable through documentation, not debugging. Clear standards prevent future implementers from repeating the same troubleshooting.

### VIII. Test Data Type Handling (NEW)

Tests MUST handle data type validation appropriately based on field types. Common patterns:

- **String fields**: Use `Should Not Be Empty` for non-empty validation
- **Numeric fields** (int, float): Use `Should Not Be Equal ${value} ${NONE}` and verify type explicitly
- **Boolean fields**: Use `Should Be True isinstance($value, bool)` for type checking
- **Enum fields**: Use `Should Contain Any` or `Should Be Equal As Strings` for value validation
- **Array/List fields**: Use `Get Length` before accessing elements

**Validation Order**:
1. Verify field exists in response: `Dictionary Should Contain Key`
2. Extract field value: `Get From Dictionary`
3. Type-appropriate validation: Choose keyword based on expected type
4. Value validation: Check against expected value range

**Rationale**: The T024 test initially failed with "Could not get length of '1'" because `Should Not Be Empty` tried to get the length of an integer `service_code`. Robot Framework keywords have implicit type expectations that aren't obvious from names. Explicit guidance prevents these failures.

## Test Organization Standards

### Suite Structure

Tests MUST be organized by user journey priority (P1, P2, P3) following the spec template pattern. Each priority level SHOULD have its own Robot Framework suite file to enable selective execution (e.g., smoke tests run P1 only).

Directory structure:
```
tests/acceptance/
├── suites/
│   ├── P1_critical_journeys.robot
│   ├── P2_standard_journeys.robot
│   └── P3_extended_journeys.robot
├── resources/
│   ├── keywords/
│   │   ├── ui_keywords.robot
│   │   ├── api_keywords.robot
│   │   └── db_keywords.robot
│   ├── libraries/
│   │   └── Open311Validator.py
│   └── variables/
│       ├── environments.robot      # MUST document all env vars
│       └── test_data.robot
├── setup/
│   └── docker-compose.test.yml
└── reports/
```

### Naming Conventions

- Test suites: `[Priority]_[domain].robot` (e.g., `P1_service_requests.robot`)
- Test cases: `[User Action] [Expected Outcome]` (e.g., `Create Service Request Returns Request ID`)
- Keywords: Verb-noun format (e.g., `Submit Service Request Form`, `Verify API Returns 201`)

### Tagging Strategy

All tests MUST include tags for:
- Priority: `P1`, `P2`, `P3`
- Component: `ui`, `api`, `database`, `integration`
- Feature: `service-requests`, `authentication`, `jurisdiction-admin`, etc.
- Type: `smoke`, `regression`, `open311-compliance`

Example: `[Tags]  P1  ui  api  service-requests  smoke`

**Conditional Teardown Logic**: Use tags to determine appropriate teardown actions:
```robot
Test Teardown - Capture Diagnostics On Failure
    ${is_ui_test}=    Run Keyword And Return Status    Should Contain    ${TEST TAGS}    ui
    Run Keyword If Test Failed And ${is_ui_test}    Capture Screenshot On Failure
    Run Keyword If Test Failed    Log API Response On Failure
```

### Library Usage Documentation

All custom keywords MUST document which Robot Framework libraries they depend on and how to access library state:

```robot
Call GET Services
    [Documentation]    Call GET /services endpoint and return response
    ...
    ...    **Returns**: (status_code, response_body)
    ...    **Library Pattern**: RESTinstance library access via $rest.instances[-1]
    ...    **Example**:
    ...        ${status}  ${body}=  Call GET Services
    ...        Should Be Equal As Numbers  ${status}  200
```

## Quality Gates

### Pre-Commit Requirements

Before committing acceptance test code:
- All tests MUST pass locally against Docker environment
- No hardcoded credentials, URLs, or environment-specific values
- All new keywords MUST have documentation strings with library dependencies
- Test case names MUST clearly describe the scenario
- All environment variables MUST be documented in `environments.robot`
- API endpoints MUST include full paths with base URL and required parameters

### CI/CD Integration

- P1 tests MUST run on every pull request (blocking merge)
- P2 tests MUST run on merge to main branch
- P3 tests SHOULD run nightly or on-demand
- Test failures MUST block deployment to staging/production
- Test execution time for P1 suite MUST NOT exceed 15 minutes

### Coverage Requirements

Acceptance tests MUST cover:
- All Open311 GeoReport v2 API endpoints (100% coverage)
- All user-facing UI workflows for service request creation and management
- Authentication flows (Google OAuth, JWT token handling)
- Image upload and SafeSearch validation
- Jurisdiction and tenant administration (admin user journeys)
- CSV download authorization

Tests MAY omit:
- Internal service layer methods (covered by unit tests)
- Database schema details (covered by migration tests)
- Edge cases better suited for API integration tests

## Governance

This constitution defines the mandatory standards for all Robot Framework acceptance testing in the Libre311 project. All test code, test data, and test infrastructure MUST comply with these principles.

### Amendment Process

Constitution changes require:
1. Documented rationale for the change (what failed/what was learned)
2. Review by at least one other team member
3. Update to all affected test suites and infrastructure
4. Version increment following semantic versioning

### Compliance Reviews

- All pull requests adding acceptance tests MUST verify alignment with principles I-VIII
- Quarterly reviews of test suite health (flakiness, execution time, coverage gaps)
- Annual review of this constitution for relevance and effectiveness

### Complexity Justification

Any violation of these principles MUST be documented in the plan.md Complexity Tracking table with:
- Which principle is violated
- Why the violation is necessary
- What simpler alternative was rejected and why

**Version**: 1.1.0 | **Ratified**: 2025-11-04 | **Last Amended**: 2025-11-04
