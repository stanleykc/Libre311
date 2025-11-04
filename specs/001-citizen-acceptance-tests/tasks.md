# Tasks: Citizen Acceptance Test Suite

**Input**: Design documents from `/specs/001-citizen-acceptance-tests/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: This feature IS the test infrastructure. Test tasks create the acceptance test suite itself.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each citizen workflow.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

All paths relative to repository root `/Users/stanleyk/dev/Libre311/`:
- Test suites: `tests/acceptance/suites/`
- Test resources: `tests/acceptance/resources/`
- Custom libraries: `tests/acceptance/resources/libraries/`
- Test data: `tests/acceptance/setup/`

---

## Phase 1: Setup (Test Infrastructure)

**Purpose**: Create test project structure and install dependencies

- [X] T001 Create test directory structure: tests/acceptance/ with suites/, resources/keywords/, resources/libraries/, resources/variables/, setup/, reports/ subdirectories
- [X] T002 Create Python virtual environment in tests/acceptance/venv-acceptance-tests and activate
- [X] T003 Install Robot Framework core 7.3.2 and verify installation
- [X] T004 [P] Install robotframework-browser 19.10.0 and run rfbrowser init for Playwright setup
- [X] T005 [P] Install RESTinstance 1.5.2 for API testing
- [X] T006 [P] Install robotframework-databaselibrary 2.0.4 and pymysql 1.1.0 for database access
- [X] T007 [P] Install robotframework-faker 5.0.0 and Faker 30.8.2 for test data generation
- [X] T008 [P] Install robotframework-dockerlibrary for container management (SKIPPED: version conflict, will use Docker CLI via Bash instead)
- [X] T009 Create requirements.txt in tests/acceptance/ with all pinned dependencies
- [X] T010 Create .gitignore in tests/acceptance/ to exclude venv, reports/, __pycache__

---

## Phase 2: Foundational (Test Infrastructure Core)

**Purpose**: Core test utilities and configuration that ALL user story tests depend on

**⚠️ CRITICAL**: No user story test suites can be written until this phase is complete

- [X] T011 Create environment configuration in tests/acceptance/resources/variables/environments.robot with API_BASE_URL, UI_BASE_URL, DB connection settings, BROWSER_MODE
- [X] T012 Create test data variables in tests/acceptance/resources/variables/test_data.robot with sample addresses, service codes, realistic citizen data
- [X] T013 [P] Create database keywords in tests/acceptance/resources/keywords/db_keywords.robot: Connect To Test Database, Seed Service Types, Seed Service Definitions, Seed Sample Requests, Clean Test Data, Verify Database State
- [X] T014 [P] Create API keywords in tests/acceptance/resources/keywords/api_keywords.robot: Call GET Services, Call GET Requests, Call POST Request, Call GET Request By ID, Verify Open311 Response Format
- [ ] T014B Document external service mocking strategy in tests/acceptance/resources/variables/environments.robot: Add MOCK_EXTERNAL_SERVICES boolean variable, document environment variables for UnityAuth URL, OAuth redirect URL, GCS bucket name, SafeSearch API endpoint; add comments explaining Browser Library network routing for external service interception per constitution Principle I
- [X] T015 [P] Create UI keywords in tests/acceptance/resources/keywords/ui_keywords.robot: Open Libre311 UI, Navigate To Services Page, Navigate To Requests Page, Fill Request Submission Form, Verify Element Visible, Capture Screenshot On Failure
- [X] T016 Create Open311Validator.py custom library in tests/acceptance/resources/libraries/ with methods: validate_service_list_response, validate_service_definition_response, validate_service_request_response, validate_request_id_format, validate_open311_required_fields
- [X] T017 Create TestDataGenerator.py custom library in tests/acceptance/resources/libraries/ with methods: generate_realistic_name, generate_email, generate_us_phone_number, generate_minneapolis_address_with_coordinates, generate_service_request_description, generate_test_user
- [X] T018 Create database seeding script in tests/acceptance/setup/seed_test_data.py to insert service types, service definitions, and sample service requests
- [X] T019 Create database cleanup script in tests/acceptance/setup/cleanup_test_data.py to delete all test data where created_for_testing=true
- [X] T020 Create test image assets in tests/acceptance/resources/test_images/: pothole_sample_1.jpg, streetlight_broken.jpg, graffiti_sample.jpg, huge_image.jpg (>10MB), inappropriate_content.jpg, document.pdf (placeholders created, replace with actual images)
- [X] T021 Create Docker health check keywords in tests/acceptance/resources/keywords/docker_keywords.robot: Verify Docker Environment Ready, Check Container Status, Collect Container Logs On Failure
- [ ] T021B Verify Docker CLI alternative to robotframework-dockerlibrary: Test all Docker operations work via Bash commands (docker ps, docker inspect, docker logs, docker exec), validate T021 keywords function correctly with Process library instead of DockerLibrary, document decision rationale in quickstart.md troubleshooting section

**Checkpoint**: Foundation ready - user story test suites can now be written in parallel

---

## Phase 3: User Story 1 - Browse Available Services (Priority: P1) 🎯 MVP

**Goal**: Create test suite validating citizens can view service types and definitions without authentication

**Independent Test**: Run P1_browse_services.robot independently after Docker environment is running and database is seeded

### Test Suite for User Story 1

- [X] T022 [US1] Create test suite file tests/acceptance/suites/P1_browse_services.robot with suite setup (seed services), suite teardown (clean data), and tags [P1, ui, api, smoke, browse]
- [X] T023 [P] [US1] Test case "Browse Existing Service Requests" in P1_browse_services.robot: Navigate to UI, verify home page displays existing service requests with details (service type, location, status badge), verify map view with markers, verify New Request button available
- [X] T024 [P] [US1] Test case "API GET /services Returns Valid Open311 Response" in P1_browse_services.robot: Call GET /services, validate response structure, verify Open311 required fields (service_code, service_name, description, metadata, type)
- [ ] T025 [P] [US1] Test case "View Service Details Shows Description and Requirements" in P1_browse_services.robot: Click service type, verify detail view, check description and required attributes displayed
- [ ] T026 [P] [US1] Test case "API GET /services/{code} Returns Service Definition" in P1_browse_services.robot: Call GET /services/POTHOLE, validate attributes structure, verify Open311 compliance
- [ ] T027 [P] [US1] Test case "Services Organized By Category" in P1_browse_services.robot: Verify UI groups services by category (Streets & Roads, Public Safety, Vandalism)
- [ ] T028 [P] [US1] Test case "Service Definition Shows Expected Response Time" in P1_browse_services.robot: Select service definition subtype, verify expected_response_time displayed
- [ ] T029 [P] [US1] Test case "API Discovery Endpoint Returns Valid Configuration" in P1_browse_services.robot: Call GET /discovery, validate changeset, contact, endpoints array
- [ ] T030 [P] [US1] Edge case "Service With No Requests Shows Empty State" in P1_browse_services.robot: Navigate to service type with zero requests, verify "No requests found" message displayed

**Checkpoint**: At this point, User Story 1 tests should pass when Docker environment is running

---

## Phase 4: User Story 2 - View Existing Service Requests (Priority: P1)

**Goal**: Create test suite validating citizens can view, filter, and search existing service requests

**Independent Test**: Run P1_view_requests.robot independently after database has sample service requests seeded

### Test Suite for User Story 2

- [ ] T031 [US2] Create test suite file tests/acceptance/suites/P1_view_requests.robot with suite setup (seed 20-30 sample requests with mix of statuses), suite teardown, tags [P1, ui, api, smoke, view]
- [ ] T032 [P] [US2] Test case "View Requests Map Shows Request Markers" in P1_view_requests.robot: Navigate to requests page, verify map visible, verify request markers displayed at correct coordinates
- [ ] T033 [P] [US2] Test case "Click Request Marker Shows Popup With Details" in P1_view_requests.robot: Click map marker, verify popup displays request ID, service type, description, status, date
- [ ] T034 [P] [US2] Test case "Filter Requests By Service Type" in P1_view_requests.robot: Apply service type filter (POTHOLE), verify only POTHOLE requests displayed, verify API call GET /requests?service_code=POTHOLE
- [ ] T035 [P] [US2] Test case "Filter Requests By Status" in P1_view_requests.robot: Apply status filter (open), verify only open requests displayed, verify API response filtering
- [ ] T036 [P] [US2] Test case "Filter Requests By Date Range" in P1_view_requests.robot: Apply date range filter, verify only requests within range displayed, verify API parameters start_date and end_date
- [ ] T037 [P] [US2] Test case "Switch To List View Shows Requests Table" in P1_view_requests.robot: Click list view toggle, verify table displayed with columns: ID, Service Type, Address, Status, Date
- [ ] T038 [P] [US2] Test case "Search Requests By Address" in P1_view_requests.robot: Enter address in search, verify requests near that address displayed
- [ ] T039 [P] [US2] Test case "View Full Request Details" in P1_view_requests.robot: Click request, verify detail page shows complete history, description, images, status updates
- [ ] T040 [P] [US2] Test case "API GET /requests Returns Multiple Requests" in P1_view_requests.robot: Call GET /requests, validate response is array, verify Open311 format, check descending date order
- [ ] T041 [P] [US2] Test case "API GET /requests/{id} Returns Single Request" in P1_view_requests.robot: Call GET /requests/REQ-12345, validate response array with one item, verify all required fields
- [ ] T042 [P] [US2] Test case "Request Details Show Status History Timeline" in P1_view_requests.robot: View request with status history, verify timeline shows all transitions with timestamps
- [ ] T043 [P] [US2] Test case "Request With Staff Updates Shows Comments" in P1_view_requests.robot: View resolved request, verify staff updates displayed in timeline
- [ ] T044 [P] [US2] Edge case "No Requests In Filtered View Shows Empty State" in P1_view_requests.robot: Apply filter that matches no requests, verify empty state message displayed
- [ ] T045 [P] [US2] Edge case "Invalid Request ID Returns 404" in P1_view_requests.robot: Call API GET /requests/INVALID-ID, verify 404 status, verify error message "Request not found"

**Checkpoint**: At this point, User Stories 1 AND 2 tests should both pass independently

---

## Phase 5: User Story 3 - Submit Service Request Without Account (Priority: P2)

**Goal**: Create test suite validating anonymous citizens can submit service requests with all required fields and optional images

**Independent Test**: Run P2_submit_anonymous.robot independently, verify new requests appear in database and can be retrieved via tracking number

### Test Suite for User Story 3

- [ ] T046 [US3] Create test suite file tests/acceptance/suites/P2_submit_anonymous.robot with suite setup (seed services, service definitions), suite teardown (clean submitted requests), tags [P2, ui, api, submit, anonymous]
- [ ] T047 [P] [US3] Test case "Navigate To Submit Form From Service Selection" in P2_submit_anonymous.robot: Browse services, click "Report this issue", verify form pre-populated with selected service type
- [ ] T048 [P] [US3] Test case "Submit Form Validates Required Fields" in P2_submit_anonymous.robot: Leave description empty, attempt submit, verify form shows "Required field" error
- [ ] T049 [P] [US3] Test case "Select Location Via Map Picker Captures Coordinates" in P2_submit_anonymous.robot: Click map location, verify coordinates captured, verify address displayed in preview
- [ ] T050 [P] [US3] Test case "Enter Address Resolves To Coordinates" in P2_submit_anonymous.robot: Type address in field, verify geocoding, verify lat/long populated
- [ ] T051 [P] [US3] Test case "Upload Photo Attaches Image To Request" in P2_submit_anonymous.robot: Select pothole_sample_1.jpg, verify upload success, verify preview shown
- [ ] T052 [P] [US3] Test case "Submit Complete Request Returns Tracking Number" in P2_submit_anonymous.robot: Fill all fields (service, location, description, contact), submit, verify 201 response, verify tracking number displayed in confirmation message
- [ ] T053 [P] [US3] Test case "API POST /requests Creates New Request" in P2_submit_anonymous.robot: Call POST /requests with all required fields, verify 201 Created, verify response includes service_request_id, verify database insert
- [ ] T054 [P] [US3] Test case "Submitted Request Appears In Browse View" in P2_submit_anonymous.robot: Submit request, navigate to browse view, verify new request visible on map and list
- [ ] T055 [P] [US3] Test case "Form Preserves Data On Navigation Away" in P2_submit_anonymous.robot: Fill partial form, navigate away, return, verify browser persists form data
- [ ] T056 [P] [US3] Test case "Mobile Device Can Upload Photo From Camera Or Gallery" in P2_submit_anonymous.robot: Set mobile viewport, click upload, verify camera/gallery options available (Browser Library mobile emulation)
- [ ] T057 [P] [US3] Test case "Submit Request With Minimal Fields" in P2_submit_anonymous.robot: Submit with only service_code, lat/long, description (no contact info), verify success
- [ ] T058 [P] [US3] Test case "Submit Request With All Optional Fields" in P2_submit_anonymous.robot: Include service-specific attributes (POTHOLE_SIZE=LARGE), verify attributes saved
- [ ] T059 [P] [US3] Edge case "Missing Required Field Prevents Submission" in P2_submit_anonymous.robot: Omit description, attempt submit, verify API returns 400, verify UI highlights missing field
- [ ] T060 [P] [US3] Edge case "Invalid Email Format Shows Error" in P2_submit_anonymous.robot: Enter "notanemail", verify client-side validation error
- [ ] T061 [P] [US3] Edge case "Image Larger Than 10MB Rejected" in P2_submit_anonymous.robot: Upload huge_image.jpg (>10MB), verify error "Image must be under 10 MB"
- [ ] T062 [P] [US3] Edge case "Inappropriate Image Content Rejected" in P2_submit_anonymous.robot: Upload inappropriate_content.jpg, verify SafeSearch mock returns rejection, verify error message displayed
- [ ] T063 [P] [US3] Edge case "Location Outside Jurisdiction Boundary Rejected" in P2_submit_anonymous.robot: Enter coordinates outside test jurisdiction, verify API returns 400, verify error "outside our service area"
- [ ] T064 [P] [US3] Edge case "Special Characters In Description Handled Correctly" in P2_submit_anonymous.robot: Submit description with emojis, quotes, <script> tags, verify XSS prevention, verify data stored safely
- [ ] T065 [P] [US3] Edge case "Network Failure During Submission Allows Retry" in P2_submit_anonymous.robot: Mock network failure (Browser Library routing), verify error displayed, verify form data preserved for retry

**Checkpoint**: At this point, User Stories 1, 2, AND 3 tests should all pass independently

---

## Phase 6: User Story 4 - Track Service Request Status (Priority: P2)

**Goal**: Create test suite validating citizens can track request status via tracking number or email lookup

**Independent Test**: Run P2_track_request.robot independently with pre-seeded requests, verify tracking and status display

### Test Suite for User Story 4

- [ ] T066 [US4] Create test suite file tests/acceptance/suites/P2_track_request.robot with suite setup (seed requests with known tracking IDs and status history), suite teardown, tags [P2, ui, api, track]
- [ ] T067 [P] [US4] Test case "Track Request By Tracking Number" in P2_track_request.robot: Enter tracking number REQ-12345, verify request details displayed
- [ ] T068 [P] [US4] Test case "Track Request By Email Address" in P2_track_request.robot: Enter email used in submission, verify all requests for that email displayed
- [ ] T069 [P] [US4] Test case "Request Status Shows Timeline" in P2_track_request.robot: View tracked request, verify timeline displays: submitted, assigned, in_progress, resolved with timestamps
- [ ] T070 [P] [US4] Test case "Staff Updates Visible In Status Timeline" in P2_track_request.robot: Track request with staff comments, verify comments displayed with timestamps
- [ ] T071 [P] [US4] Test case "Resolved Request Shows Resolution Details" in P2_track_request.robot: Track resolved request, verify resolution date, staff notes, before/after photos (if available)
- [ ] T072 [P] [US4] Test case "Opt In To Email Notifications" in P2_track_request.robot: Track request, click "Notify me of updates", verify opt-in confirmation
- [ ] T073 [P] [US4] Test case "API GET /requests/{id} Returns Status History" in P2_track_request.robot: Call GET /requests/REQ-12345, verify status_history array, verify timestamps ISO 8601
- [ ] T074 [P] [US4] Edge case "Invalid Tracking Number Returns Clear Error" in P2_track_request.robot: Enter tracking number "INVALID-999", verify error "Request not found. Please check your tracking number"
- [ ] T075 [P] [US4] Edge case "Email With No Requests Returns Empty State" in P2_track_request.robot: Enter email with no submissions, verify message "No requests found for this email"

**Checkpoint**: At this point, User Stories 1, 2, 3, AND 4 tests should all pass independently

---

## Phase 7: User Story 5 - Submit Service Request With Account (Priority: P3)

**Goal**: Create test suite validating authenticated citizens can submit requests with pre-filled contact info and access request dashboard

**Independent Test**: Run P3_submit_authenticated.robot independently, verify OAuth mock works, verify authenticated submission and dashboard

### Test Suite for User Story 5

- [ ] T076 [US5] Create test suite file tests/acceptance/suites/P3_submit_authenticated.robot with suite setup (seed test users, mock OAuth), suite teardown, tags [P3, ui, api, authenticated, oauth]
- [ ] T077 [P] [US5] Test case "Sign In Redirects To Google OAuth" in P3_submit_authenticated.robot: Click "Sign In", verify OAuth redirect URL (mock via Browser Library network routing)
- [ ] T078 [P] [US5] Test case "Successful OAuth Returns To Libre311 Logged In" in P3_submit_authenticated.robot: Complete OAuth flow (mocked), verify redirect back to Libre311, verify user name displayed
- [ ] T079 [P] [US5] Test case "My Requests Dashboard Shows User Submissions" in P3_submit_authenticated.robot: Sign in as test user with pre-seeded requests, navigate to dashboard, verify user's requests displayed
- [ ] T080 [P] [US5] Test case "Authenticated Submission Pre Fills Contact Info" in P3_submit_authenticated.robot: Sign in, navigate to submit form, verify name and email pre-filled from OAuth profile
- [ ] T081 [P] [US5] Test case "Dashboard Filters User Requests By Status" in P3_submit_authenticated.robot: Apply filter on dashboard (open requests only), verify only user's open requests shown
- [ ] T082 [P] [US5] Test case "Dashboard Sorts Requests By Date" in P3_submit_authenticated.robot: View dashboard, verify requests sorted by date descending (most recent first)
- [ ] T083 [P] [US5] Test case "Authenticated User Can Add Follow Up Comments" in P3_submit_authenticated.robot: View own request, add follow-up comment, verify comment saved and displayed
- [ ] T084 [P] [US5] Test case "Sign Out Logs User Out" in P3_submit_authenticated.robot: Click "Sign Out", verify logout, verify can still browse anonymously
- [ ] T085 [P] [US5] Test case "API GET /users/me/requests Requires Authentication" in P3_submit_authenticated.robot: Call GET /users/me/requests without auth header, verify 401 Unauthorized
- [ ] T086 [P] [US5] Test case "API GET /users/me/requests Returns Only User Requests" in P3_submit_authenticated.robot: Call with valid JWT token, verify response contains only user's requests, verify does not include other users' requests
- [ ] T087 [P] [US5] Edge case "OAuth Authentication Failure Shows Error" in P3_submit_authenticated.robot: Mock OAuth failure, verify error message, verify can retry or continue anonymously
- [ ] T088 [P] [US5] Edge case "OAuth Cancelled By User Handles Gracefully" in P3_submit_authenticated.robot: Mock user cancels OAuth, verify redirect back to Libre311, verify no error, verify anonymous access continues
- [ ] T089 [P] [US5] Edge case "Expired Session Prompts Re Authentication" in P3_submit_authenticated.robot: Mock expired JWT, attempt dashboard access, verify redirect to login, verify no data loss
- [ ] T090 [P] [US5] Edge case "Concurrent Requests From Same User" in P3_submit_authenticated.robot: Submit two requests rapidly, verify both have unique IDs, verify both appear in dashboard

**Checkpoint**: All 5 user story test suites should now pass independently

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple test suites and overall test infrastructure

- [ ] T091 [P] Create README.md in tests/acceptance/ documenting test execution, prerequisites, troubleshooting
- [ ] T092 [P] Create CI/CD integration example in .github/workflows/acceptance-tests.yml for GitHub Actions
- [ ] T093 Configure Pabot for parallel test execution with --processes 4
- [ ] T094 [P] Add performance assertions to all API test cases: verify 95% of requests complete in <10 seconds
- [ ] T095 [P] Create test execution wrapper script tests/acceptance/run_tests.sh with Docker health check, database seeding, and test execution
- [ ] T096 Add Open311 compliance tag validation: verify all open311-compliance tagged tests call Open311Validator
- [ ] T097 [P] Create test data cleanup verification: ensure all tests clean up data they create (idempotency check)
- [ ] T098 Add screenshot on failure for all UI tests: verify Browser Library captures screenshots in reports/browser/screenshot/
- [ ] T099 [P] Create log collection keyword: Collect All Diagnostics On Failure (API logs, DB dumps, container logs)
- [ ] T100 Optimize test data seeding: reduce seed data volume to improve P1 suite execution time (<5 min target)
- [ ] T101 Validate quickstart.md instructions: run through quickstart guide end-to-end, verify all commands work
- [ ] T102 [P] Add test execution timing report: verify P1 <5min, P2 <10min, P3 <15min per success criteria

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user story tests
- **User Story Tests (Phase 3-7)**: All depend on Foundational phase completion
  - User story tests can then proceed in parallel (if team has capacity)
  - Or sequentially in priority order (P1 US1 → P1 US2 → P2 US3 → P2 US4 → P3 US5)
- **Polish (Phase 8)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (Browse Services - P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (View Requests - P1)**: Can start after Foundational - Independent (tests viewing pre-seeded requests)
- **User Story 3 (Submit Anonymous - P2)**: Can start after Foundational - Independent (tests submission flow)
- **User Story 4 (Track Request - P2)**: Can start after Foundational - Independent (tests tracking pre-seeded requests)
- **User Story 5 (Authenticated Submit - P3)**: Can start after Foundational - Independent (tests OAuth + authenticated submission)

### Within Each User Story

- All test cases within a user story marked [P] can run in parallel (Robot Framework supports parallel test execution)
- Test suite setup must complete before any tests run
- Test suite teardown runs after all tests complete
- Each test case should be independently executable (no inter-test dependencies)

### Parallel Opportunities

- All Setup tasks (T004-T008) can run in parallel (different pip installs)
- All Foundational tasks (T013-T015, T020) can run in parallel within Phase 2 (different files)
- Once Foundational phase completes, all 5 user story test suites can be developed in parallel
- All test cases within a user story can be run in parallel using Pabot
- Polish tasks (T091, T092, T094, T097, T099, T102) can run in parallel

---

## Parallel Example: User Story 1 Test Cases

```bash
# All User Story 1 test cases can run in parallel (marked [P]):
pabot --processes 8 --include US1 tests/acceptance/suites/P1_browse_services.robot

# This executes T023-T030 concurrently for faster feedback
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T010) - Install Robot Framework ecosystem
2. Complete Phase 2: Foundational (T011-T021) - Build test infrastructure (CRITICAL - blocks all tests)
3. Complete Phase 3: User Story 1 (T022-T030) - Browse services tests
4. **STOP and VALIDATE**: Run P1_browse_services.robot against Docker environment
5. Deliver MVP test suite for browse functionality

### Incremental Delivery

1. Complete Setup + Foundational → Test infrastructure ready
2. Add User Story 1 tests → Run independently → MVP delivered (browse)
3. Add User Story 2 tests → Run independently → Viewing/filtering validated
4. Add User Story 3 tests → Run independently → Anonymous submission validated
5. Add User Story 4 tests → Run independently → Tracking validated
6. Add User Story 5 tests → Run independently → Authenticated workflows validated
7. Each story adds test coverage without breaking previous test suites

### Parallel Team Strategy

With multiple QA engineers or developers:

1. Team completes Setup + Foundational together (T001-T021)
2. Once Foundational is done:
   - Engineer A: User Story 1 tests (T022-T030) - Browse
   - Engineer B: User Story 2 tests (T031-T045) - View requests
   - Engineer C: User Story 3 tests (T046-T065) - Submit anonymous
   - Engineer D: User Story 4 tests (T066-T075) - Track request
   - Engineer E: User Story 5 tests (T076-T090) - Authenticated
3. Stories complete and run independently, integrate into full regression suite

---

## Test Execution Summary

### Expected Test Counts

- **User Story 1 (Browse)**: 8 test cases (T023-T030)
- **User Story 2 (View Requests)**: 15 test cases (T032-T045)
- **User Story 3 (Submit Anonymous)**: 20 test cases (T047-T065)
- **User Story 4 (Track Request)**: 10 test cases (T067-T075)
- **User Story 5 (Authenticated)**: 15 test cases (T077-T090)

**Total Test Cases**: 68 acceptance scenarios

### Coverage

- **Open311 API Compliance**: All Open311 GeoReport v2 endpoints validated (GET /services, GET /services/{code}, GET /requests, GET /requests/{id}, POST /requests)
- **UI Workflows**: All citizen user journeys validated (browse, view, submit, track, authenticate)
- **Edge Cases**: 12 edge cases covered (invalid input, size limits, content validation, network failures, authentication errors)

### Execution Time Targets

- **P1 Suite** (US1 + US2): 23 tests, target <5 minutes
- **P2 Suite** (US3 + US4): 30 tests, target <10 minutes
- **P3 Suite** (US5): 15 tests, target <15 minutes

### Independent Test Criteria

- **US1**: Run P1_browse_services.robot → All tests pass when services seeded
- **US2**: Run P1_view_requests.robot → All tests pass when sample requests seeded
- **US3**: Run P2_submit_anonymous.robot → All tests pass, new requests created and visible
- **US4**: Run P2_track_request.robot → All tests pass, tracking works for seeded requests
- **US5**: Run P3_submit_authenticated.robot → All tests pass, OAuth mock functional

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label (US1-US5) maps task to specific user story for traceability
- Each user story test suite is independently executable and validates a complete citizen workflow
- All tests use Robot Framework with Browser Library (UI), RESTinstance (API), DatabaseLibrary (data)
- Custom libraries (Open311Validator.py, TestDataGenerator.py) provide Open311-specific validation and realistic test data
- External services (UnityAuth, Google OAuth, GCS, SafeSearch, ReCaptcha) mocked via Browser Library network routing per constitution
- Database cleaned before/after each suite run using Flyway clean + migrate pattern per constitution
- Test failures capture screenshots, API logs, database dumps, and container logs per observable execution principle
- Commit after completing each user story phase (T022-T030, T031-T045, etc.) for incremental progress
- Stop at any checkpoint to validate test suite independently before proceeding
- Avoid: cross-suite dependencies, hardcoded test data, missing cleanup, non-isolated tests
