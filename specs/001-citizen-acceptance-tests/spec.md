# Feature Specification: Citizen Acceptance Test Suite

**Feature Branch**: `001-citizen-acceptance-tests`
**Created**: 2025-11-04
**Status**: Draft
**Input**: User description: "Create a specification for the creation of a comprehensive set of acceptance tests. Start with the basic browsing capabilities, then move to the creation of new service requests with basic users. We will add support for administrative capabilities later. Right now focus on 'citizen' use cases."

## Clarifications

### Session 2025-11-04

- Q: Test Framework Execution Strategy - For Robot Framework test organization, what execution model best suits your CI/CD needs? → A: Separate suite files per priority (P1.robot, P2.robot, P3.robot) with shared keywords library, enables parallel execution and fast smoke testing
- Q: External Service Mocking Strategy - What mocking approach will minimize test maintenance while ensuring reliable test execution for UnityAuth, Google OAuth, GCS, and SafeSearch? → A: Application-level test doubles: Configure Micronaut test beans to replace external service clients with in-memory stubs, fast and deterministic
- Q: Test Data Isolation Strategy - Which approach will provide the best balance of speed and isolation for test data management? → A: Full database reset per suite: DROP/CREATE all tables or TRUNCATE between suite runs using Flyway clean, fast and simple
- Q: Duplicate Request Detection - Should tests validate duplicate detection at same location? → A: No, application does not currently support duplicate detection. Remove from edge cases; keep in future considerations backlog
- Q: Image Upload Size Limit - What maximum file size should tests validate for image uploads? → A: 10 MB

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse Available Services (Priority: P1)

A citizen visits the Libre311 application to discover what types of service requests they can submit to their local government (e.g., potholes, broken streetlights, graffiti removal). They need to browse the available service categories and understand what each service type covers before deciding what to report.

**Why this priority**: This is the entry point for all citizen interactions. Without the ability to discover available services, citizens cannot effectively use the system. This represents the most basic read-only functionality and should be the foundation for all other test scenarios.

**Independent Test**: Can be fully tested by launching the application, navigating to the services list/catalog, and verifying that service types are displayed with their descriptions. No data creation or authentication required.

**Acceptance Scenarios**:

1. **Given** the Libre311 application is running, **When** a citizen navigates to the homepage, **Then** they see a list or map view of available service types
2. **Given** the service catalog is displayed, **When** a citizen clicks on a service type (e.g., "Pothole"), **Then** they see detailed information about that service including description and what information is required to submit a request
3. **Given** multiple service types exist in the system, **When** a citizen browses the service list, **Then** services are organized by category or jurisdiction for easy navigation
4. **Given** the citizen is viewing service details, **When** they select a service definition (subtype like "Pothole - Road"), **Then** they see specific requirements and expected response time for that issue type

---

### User Story 2 - View Existing Service Requests (Priority: P1)

A citizen wants to see what service requests have already been submitted in their area to avoid duplicate reports and to check the status of issues they care about. They should be able to browse requests on a map or list view, filter by location or service type, and view details of specific requests.

**Why this priority**: Preventing duplicate reports is critical for government efficiency and citizen satisfaction. This is also read-only functionality that builds on User Story 1 and is required before citizens submit their own requests.

**Independent Test**: Can be tested by seeding the database with sample service requests, then verifying citizens can view, filter, and search these requests without authentication. Delivers value by showing transparency of government operations.

**Acceptance Scenarios**:

1. **Given** service requests exist in the system, **When** a citizen views the requests page, **Then** they see requests displayed on a map with markers showing location and request type
2. **Given** the map view is displayed, **When** a citizen clicks on a request marker, **Then** they see a popup or detail panel showing request ID, service type, description, submitted date, and current status
3. **Given** many requests exist, **When** a citizen uses the filter controls, **Then** they can filter requests by service type, status (open/closed), and date range
4. **Given** the citizen is viewing the request list, **When** they switch to list view (table format), **Then** they see requests in a sortable table with columns for ID, service type, address, status, and date
5. **Given** a citizen is near a location with multiple requests, **When** they search by address or use map navigation, **Then** they see all requests within that geographic area
6. **Given** a specific request is selected, **When** the citizen views its full details, **Then** they see the complete history including description, location, any uploaded images, and status updates

---

### User Story 3 - Submit Service Request Without Account (Priority: P2)

A citizen discovers an issue in their neighborhood (pothole, broken streetlight, graffiti, etc.) and wants to report it to the local government immediately without creating an account. They should be able to fill out a form with issue details, location, contact information, and optional photos, then submit it and receive a confirmation with tracking number.

**Why this priority**: This is the core value proposition of the system—enabling citizens to report issues easily. However, it depends on being able to browse services (P1) to select what to report. Placing it as P2 ensures basic read functionality works before enabling write operations.

**Independent Test**: Can be tested by walking through the submission form flow without authentication, submitting a request with all required fields (service type, location, description, contact info), and verifying the request appears in the system with a unique tracking ID. Test can verify the request shows up in the browse view from User Story 2.

**Acceptance Scenarios**:

1. **Given** a citizen is browsing service types, **When** they select "Report this issue" or "Create Request" for a specific service, **Then** they are directed to a submission form pre-populated with the selected service type
2. **Given** the submission form is displayed, **When** the citizen fills in required fields (service type, location via map picker or address, description, contact name, email, phone), **Then** the form validates all required fields before allowing submission
3. **Given** the location field is active, **When** the citizen clicks on a map or enters an address, **Then** the system captures accurate geographic coordinates and displays the selected location on a map preview
4. **Given** the citizen wants to provide visual evidence, **When** they click "Upload Photo", **Then** they can select one or more images from their device (up to a reasonable limit like 5 images)
5. **Given** uploaded images contain inappropriate content, **When** the system processes the images, **Then** it validates images meet content policies and rejects inappropriate uploads with a clear error message
6. **Given** all required fields are completed, **When** the citizen submits the form, **Then** the system creates a new service request, returns a unique tracking number, and displays a confirmation message with the tracking number
7. **Given** a request has been submitted successfully, **When** the citizen checks the tracking number, **Then** they can view the status and details of their submitted request
8. **Given** the submission form has been partially filled, **When** the citizen navigates away and returns, **Then** the form data is preserved (browser-level persistence) to prevent data loss
9. **Given** the citizen is submitting from a mobile device, **When** they choose to upload a photo, **Then** they can use the device camera to take a photo directly or select from gallery

---

### User Story 4 - Track Service Request Status (Priority: P2)

A citizen who has submitted a service request wants to check its status without logging in. They should be able to enter their tracking number (request ID) or search by email address to find their requests and see current status, any staff updates, and estimated resolution time.

**Why this priority**: Following up on submitted requests is essential for transparency and citizen trust. This builds on User Story 3 (submission) and provides the "close the loop" functionality citizens expect. It's P2 because it depends on request submission working first.

**Independent Test**: Can be tested by seeding a request with a known tracking ID, then using the tracking/lookup feature to find it, and verifying all status information displays correctly. Tests both anonymous lookup (via tracking number) and email-based lookup.

**Acceptance Scenarios**:

1. **Given** the citizen has a tracking number from a previous submission, **When** they enter the tracking number in the "Track Request" field, **Then** the system displays the full details of that specific request including current status
2. **Given** the citizen doesn't remember their tracking number, **When** they provide their email address used during submission, **Then** the system displays all requests submitted with that email address
3. **Given** a request is being viewed via tracking lookup, **When** the citizen reviews the status, **Then** they see a timeline or status history showing when the request was submitted, when it was assigned, any updates from staff, and current status (new/open/in progress/resolved/closed)
4. **Given** government staff have added updates or comments to a request, **When** the citizen views the request status, **Then** they see these staff updates with timestamps in the request timeline
5. **Given** a request has been resolved or closed, **When** the citizen views the tracking information, **Then** they see the resolution details, any before/after photos from staff, and the date it was completed
6. **Given** the citizen is tracking a request, **When** they want to receive updates, **Then** they can opt-in to email notifications for status changes on that request

---

### User Story 5 - Submit Service Request With Account (Priority: P3)

A citizen who regularly submits service requests wants to create an account so they can manage all their submissions in one place, track multiple requests, and maintain a history. They authenticate via Google OAuth (the supported identity provider), access their dashboard showing all their requests, and can submit new requests with pre-filled contact information.

**Why this priority**: This is a convenience feature for power users. The anonymous submission (P2) already provides core functionality, so account-based submission is an enhancement rather than a requirement. It's P3 because it's valuable but not critical for the minimum viable test suite.

**Independent Test**: Can be tested by authenticating with a test Google account, verifying the user dashboard displays correctly with zero requests initially, then submitting a request while authenticated and verifying it appears in the user's request history. Tests the full authenticated user journey independently from anonymous usage.

**Acceptance Scenarios**:

1. **Given** the citizen wants to create an account, **When** they click "Sign In" or "Create Account", **Then** they are redirected to Google OAuth authentication flow
2. **Given** the Google OAuth flow is initiated, **When** the citizen successfully authenticates with Google, **Then** they are redirected back to Libre311 and automatically logged in with their Google email as their account identifier
3. **Given** the citizen is logged in, **When** they navigate to their dashboard or "My Requests" page, **Then** they see a list of all service requests they have submitted while authenticated
4. **Given** the citizen is logged in and creating a new request, **When** the submission form loads, **Then** their contact information (name, email from Google profile) is automatically pre-filled
5. **Given** the citizen has multiple requests in their account, **When** they view their dashboard, **Then** they can sort and filter their own requests by date, status, and service type
6. **Given** the citizen is viewing a request they submitted while logged in, **When** they access the request details, **Then** they see all the same information available via anonymous tracking, plus the ability to add follow-up comments or updates
7. **Given** the citizen no longer wants to use the account, **When** they click "Sign Out", **Then** they are logged out and can continue using the system anonymously

---

### Edge Cases

- **Service with no requests**: What happens when a citizen browses a service type that has never had any requests submitted? The system should display an empty state with helpful text like "No requests found for this service type" rather than an error.

- **Invalid tracking number**: What happens when a citizen enters a tracking number that doesn't exist in the system? The system should display a clear message: "Request not found. Please check your tracking number and try again."

- **Map area with no service coverage**: What happens when a citizen tries to submit a request for a location outside any configured jurisdiction boundaries? The system should validate the location and display a clear error: "This location is outside our service area. Please contact [jurisdiction name] directly."

- **Image upload too large**: What happens when a citizen tries to upload an image larger than the system's file size limit (10 MB)? The system should reject the upload with a specific error: "Image must be under 10 MB. Please resize or choose a different image."

- **Required field missing**: What happens when a citizen tries to submit a request without filling in a required field (e.g., no description)? The system should prevent submission and highlight all missing required fields with specific error messages.

- **Email format invalid**: What happens when a citizen enters an incorrectly formatted email address? The system should validate email format client-side and display an error: "Please enter a valid email address."

- **Network failure during submission**: What happens when network connectivity is lost while submitting a request? The system should detect the failure and allow the citizen to retry submission without losing entered data, or save a draft locally.

- **OAuth authentication failure**: What happens when Google OAuth authentication fails or is cancelled by the user? The system should handle the failure gracefully, display an error message, and allow the citizen to retry or continue using the system anonymously.

- **Expired OAuth session**: What happens when a logged-in citizen's session expires while they're using the application? The system should detect the expired session and either automatically refresh the token or prompt the citizen to re-authenticate without losing unsaved work.

- **Concurrent request submission**: What happens when a citizen submits multiple requests in quick succession? Each submission should be processed independently with unique tracking IDs, without race conditions or data corruption.

- **Special characters in input**: What happens when a citizen enters special characters, emojis, or very long text in description fields? The system should handle these gracefully, either accepting them if safe or providing clear validation rules.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Test suite MUST validate that citizens can view a complete list of available service types and definitions without authentication
- **FR-002**: Test suite MUST verify that service type details display correctly including service name, description, category, and any required attributes for submission
- **FR-003**: Test suite MUST confirm that citizens can view existing service requests on both map and list views
- **FR-004**: Test suite MUST validate that request filtering works correctly by service type, status, date range, and geographic area
- **FR-005**: Test suite MUST verify that individual service request details display all required information (ID, service type, location, description, status, timestamps, images)
- **FR-006**: Test suite MUST confirm that citizens can submit service requests anonymously with all required fields (service type, location, description, contact information)
- **FR-007**: Test suite MUST validate that location capture works correctly via both map picker and address entry, producing valid geographic coordinates
- **FR-008**: Test suite MUST verify that image upload functionality works for common image formats (JPEG, PNG) up to 10 MB file size, and rejects files exceeding this limit with a clear error message
- **FR-009**: Test suite MUST confirm that inappropriate image content is detected and rejected per SafeSearch validation
- **FR-010**: Test suite MUST validate that successful request submission returns a unique tracking number and confirmation message
- **FR-011**: Test suite MUST verify that citizens can track request status using tracking number or email address lookup
- **FR-012**: Test suite MUST confirm that request status timeline displays all status changes and staff updates in chronological order
- **FR-013**: Test suite MUST validate that Google OAuth authentication flow works correctly for account creation and login
- **FR-014**: Test suite MUST verify that authenticated citizens can access a dashboard showing all their submitted requests
- **FR-015**: Test suite MUST confirm that contact information is automatically pre-filled for authenticated users when creating new requests
- **FR-016**: Test suite MUST validate that form validation works correctly, preventing submission with missing required fields and providing clear error messages
- **FR-017**: Test suite MUST verify that the system complies with Open311 GeoReport v2 API specification for all relevant endpoints (service list, service definition, request creation, request retrieval)
- **FR-018**: Test suite MUST confirm that all test scenarios run successfully against the Docker-composed environment (libre311-api, libre311-ui-dev, libre311-db)
- **FR-019**: Test suite MUST perform full database reset (Flyway clean + migrate) before each suite execution and seed required test data, ensuring complete data isolation and known clean state between test runs
- **FR-020**: Test suite MUST verify that tests capture appropriate diagnostics on failure (screenshots for UI tests, API request/response logs, browser console errors)
- **FR-021**: Test suite MUST be organized into separate Robot Framework files by priority (P1.robot for browse/view scenarios, P2.robot for submit/track scenarios, P3.robot for authenticated scenarios) with a shared keywords library (common_keywords.robot) containing reusable test operations
- **FR-022**: Test infrastructure MUST configure Micronaut test beans as application-level test doubles for external services (UnityAuth, Google OAuth, Google Cloud Storage, SafeSearch API), replacing production service clients with in-memory stubs that return deterministic responses

### Key Entities

- **Test Suite**: A collection of automated Robot Framework tests organized into separate suite files by priority (P1.robot, P2.robot, P3.robot), with a shared keywords library for common operations. Each suite is independently executable and supports parallel execution for fast CI/CD feedback
- **Service Type**: A category of issue that citizens can report (e.g., Pothole, Graffiti, Broken Streetlight), corresponds to the Service entity in the application data model
- **Service Definition**: A specific subtype of a service (e.g., "Pothole - Road" vs "Pothole - Sidewalk"), provides additional classification
- **Service Request**: A citizen-submitted report of an issue, contains location, description, service type, contact information, optional images, and status tracking information
- **Tracking Number**: A unique identifier (request ID) assigned to each service request, allows anonymous lookup and status tracking
- **Test Environment**: The Docker-composed stack of libre311-api, libre311-ui-dev, and libre311-db containers running on unity-network
- **Test Data**: Seed data for services, service definitions, and sample service requests used to validate read-only functionality
- **Authentication Session**: OAuth-based session created when a citizen logs in via Google, enables access to authenticated features like request dashboard
- **Request Status**: Current state of a service request (new, open, in progress, resolved, closed), tracked over time in status history
- **Geographic Location**: Coordinates (latitude/longitude) and address information identifying where a service request issue exists

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Test suite executes all P1 priority tests (browse services, view requests) in under 5 minutes against Docker environment
- **SC-002**: Test suite achieves 100% coverage of all Open311 GeoReport v2 API endpoints used in citizen workflows (GET /services, GET /requests, POST /requests)
- **SC-003**: Test suite achieves 100% coverage of critical UI workflows (browse services, view requests, submit request, track request) across both anonymous and authenticated user paths
- **SC-004**: All test failures produce actionable diagnostic artifacts including screenshots, API logs, and browser console errors within 2 minutes of test completion
- **SC-005**: Test suite can be executed independently with zero manual setup beyond starting the Docker environment and running the test command
- **SC-006**: Each test suite (P1, P2, P3) can run in isolation and produce identical results regardless of execution order or parallel execution
- **SC-007**: Test execution detects and reports Open311 specification compliance violations with specific details about non-compliant request/response formats
- **SC-008**: 95% of test scenarios validate expected behavior within 10 seconds of action (e.g., form submission, request lookup) to catch performance regressions
- **SC-009**: Test suite validates at least 10 edge cases per user story to ensure robust error handling and user-friendly error messages
- **SC-010**: Test infrastructure supports tagging and selective execution (e.g., "run only P1 smoke tests" or "run only API tests") to enable fast feedback in CI/CD pipelines

## Assumptions

- **Test Environment**: Tests will run against a local Docker environment with all three tiers (API, UI, Database) running as defined in `docker-compose.local.yml`
- **Test Data Management**: Test suites will reset the database using Flyway clean, then apply Flyway migrate to restore schema, followed by seeding test data via API calls or direct database inserts. This ensures each suite run starts with a known clean database state
- **External Service Mocking**: UnityAuth, Google OAuth, Google Cloud Storage, and SafeSearch API calls will use application-level test doubles implemented as Micronaut test beans that replace external service clients with in-memory stubs, ensuring fast and deterministic test execution without external dependencies
- **Browser Compatibility**: UI tests will run against a single modern browser (Chrome/Chromium) headless mode for CI/CD environments, with option to run headed mode for local debugging
- **Image Testing**: Image upload tests will use pre-generated test images (both valid and invalid content) stored in the test resources directory
- **Open311 Validation**: An Open311 compliance validation library will be created or used to validate API responses against the GeoReport v2 specification schema
- **Authentication Testing**: OAuth testing will use stubbed Micronaut test beans returning predefined OAuth tokens and user profiles, avoiding real Google authentication to eliminate rate limits and credential management complexity
- **Network Reliability**: Tests assume stable network connectivity between containers; transient network failures are not explicitly tested in this phase
- **Data Isolation**: Each test suite execution will perform a full database reset using Flyway clean (DROP/CREATE all tables) or TRUNCATE operations before test execution to ensure complete isolation and a known clean state. Flyway migrate will then restore the schema and seed required test data
- **Performance Baseline**: Expected response times are based on local Docker environment performance; CI/CD environments may have different baselines that need adjustment

## Out of Scope / Future Considerations

The following capabilities are not currently implemented in the application and are therefore excluded from this test suite. These items are documented for future consideration:

- **Duplicate Request Detection**: The application does not currently detect or warn about duplicate service requests at the same or nearby locations. Future enhancement could include proximity-based duplicate detection to warn citizens before submitting potentially duplicate requests
