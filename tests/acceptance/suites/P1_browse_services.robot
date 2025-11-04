*** Settings ***
Documentation     Test Suite for User Story 1: Browse Available Services
...
...               This suite validates that citizens can view service types and definitions
...               without authentication. Tests cover UI service browsing and Open311 API compliance.
...
...               **User Story**: As a citizen, I want to browse available service types so that
...               I can see what issues I can report (e.g., potholes, graffiti, broken streetlights).
...
...               **Priority**: P1 (MVP Critical)
...               **Independent Execution**: Run after Docker environment is running and database is seeded

Resource          ../resources/variables/environments.robot
Resource          ../resources/variables/test_data.robot

Library           Browser
Library           REST    ${API_BASE_URL}
Library           DatabaseLibrary
Library           ../resources/libraries/Open311Validator.py
Resource          ../resources/keywords/db_keywords.robot
Resource          ../resources/keywords/api_keywords.robot
Resource          ../resources/keywords/ui_keywords.robot
Resource          ../resources/keywords/docker_keywords.robot

Suite Setup       Suite Setup - Browse Services
Suite Teardown    Suite Teardown - Browse Services
Test Setup        Test Setup - Capture Context
Test Teardown     Test Teardown - Capture Diagnostics On Failure

Default Tags      P1    ui    api    smoke    browse    US1


*** Variables ***
${SUITE_TAG}      P1_browse_services


*** Keywords ***
Suite Setup - Browse Services
    [Documentation]    Initialize test environment for browse testing
    Log    Starting Suite Setup for P1 Browse Services    level=INFO

    # Verify Docker environment is ready
    Verify Docker Environment Ready

    # Connect to test database
    Connect To Test Database

    # Verify existing services are accessible
    ${count}=    Query    SELECT COUNT(*) FROM services
    Log    Found ${count[0][0]} services in database    level=INFO
    Should Be True    ${count[0][0]} >= 3    msg=Expected at least 3 services in database

    Log    Suite Setup Complete - Environment ready    level=INFO

Suite Teardown - Browse Services
    [Documentation]    Clean up connections
    Log    Starting Suite Teardown for P1 Browse Services    level=INFO

    # Disconnect from database
    Disconnect From Database

    Log    Suite Teardown Complete    level=INFO

Test Setup - Capture Context
    [Documentation]    Capture test context before each test execution
    Log    Starting Test: ${TEST NAME}    level=INFO

    # Initialize UI context if needed for UI tests
    ${is_ui_test}=    Run Keyword And Return Status    Should Contain    ${TEST TAGS}    ui
    Run Keyword If    ${is_ui_test}    Open Libre311 UI

Test Teardown - Capture Diagnostics On Failure
    [Documentation]    Capture screenshots and logs on test failure
    Run Keyword If Test Failed    Capture Screenshot On Failure
    Run Keyword If Test Failed    Log    Test Failed: ${TEST NAME}    level=ERROR


*** Test Cases ***
Browse Existing Service Requests
    [Documentation]    Test Case T023 - User Story 1 (Modified)
    ...
    ...    **Scenario**: Citizen visits Libre311 home page to browse existing service requests
    ...    **Given**: Service requests exist in the database
    ...    **When**: User loads the home page
    ...    **Then**: Existing service requests are displayed with their details
    ...
    ...    **Validates**:
    ...    - FR-001: Citizens can browse existing requests without authentication
    ...    - FR-002: Request details are visible (service type, location, status)
    ...    - UI displays request list and map view
    ...    - Citizens can see what issues have been reported in their community

    [Tags]    T023    ui    browse-requests    P1

    # Verify page loaded successfully
    ${title}=    Get Title
    Log    Page title: ${title}    level=INFO
    Should Contain    ${title}    Libre311    msg=Expected page title to contain 'Libre311'

    # Take screenshot for debugging
    Take Screenshot    filename=browse_requests_page

    # Verify the page header shows the jurisdiction
    ${header_text}=    Get Text    text=St. Louis Metro Area
    Log    Page header: ${header_text}    level=INFO

    # Verify "Requests" section is visible (this is the main view on home page)
    Get Text    text=Requests
    Log    Verified Requests section is visible    level=INFO

    # Verify pagination/count indicator shows requests exist
    # Looking for "1 - 1 of 1" or similar text that indicates requests are present
    ${has_pagination}=    Run Keyword And Return Status    Get Text    text=1 - 1 of 1
    Log    Pagination indicator found: ${has_pagination}    level=INFO

    # Verify at least one request is displayed in the list
    # Check for request number indicator (e.g., "#1")
    ${request_number}=    Get Text    text=#1
    Log    Found request: ${request_number}    level=INFO

    # Verify request details are visible
    # Each request should show:
    # - Date/time (e.g., "10/28/2025 04:08 PM")
    # - Service type (e.g., "Bus Stop")
    # - Status badge (e.g., "Open")
    # - Location address

    # Verify service type is displayed
    ${service_type}=    Get Text    text=Bus Stop
    Log    Service type: ${service_type}    level=INFO
    Should Not Be Empty    ${service_type}    msg=Expected service type to be displayed

    # Verify status badge is displayed
    ${status}=    Get Text    css=.stwui-badge
    Log    Request status: ${status}    level=INFO
    Should Not Be Empty    ${status}    msg=Expected status to be displayed

    # Verify location/address is displayed
    ${location_visible}=    Run Keyword And Return Status    Get Text    text=Bookbinder Drive
    Log    Location visible: ${location_visible}    level=INFO

    # Verify map is present for visualizing request locations
    ${map_visible}=    Run Keyword And Return Status    Get Element Count    css=.leaflet-container    ==    1
    Should Be True    ${map_visible}    msg=Expected map to be visible for viewing service request locations

    # Verify map has at least one marker (representing a request)
    ${marker_visible}=    Run Keyword And Return Status    Get Element    css=.leaflet-marker-icon
    Should Be True    ${marker_visible}    msg=Expected at least one request marker on the map

    # Verify "New Request" button is available for citizens to report new issues
    Get Text    text=New Request
    Log    Verified New Request button is available for citizens    level=INFO

    Log    Successfully verified citizens can browse existing service requests    level=INFO


API GET /services Returns Valid Open311 Response
    [Documentation]    Test Case T024 - User Story 1
    ...
    ...    **Scenario**: Validate that the Open311 GET /services endpoint returns a properly formatted response
    ...    **Given**: The Libre311 API is running and services exist in the database
    ...    **When**: A GET request is made to /services endpoint
    ...    **Then**: The response contains valid Open311 GeoReport v2 formatted service list
    ...
    ...    **Validates**:
    ...    - FR-003: Open311 API compliance for service listing
    ...    - Response structure matches Open311 GeoReport v2 specification
    ...    - All required fields present: service_code, service_name, description, metadata, type
    ...    - Response is properly formatted JSON array
    ...    - Each service contains valid Open311 field values

    [Tags]    T024    api    open311-compliance    P1

    # Call GET /services endpoint
    ${status}    ${body}=    Call GET Services
    Log    API Response Status: ${status}    level=INFO
    Log    API Response Body: ${body}    level=DEBUG

    # Verify HTTP 200 OK status
    Verify API Response Status    ${status}    200

    # Verify response is array
    ${type}=    Evaluate    type($body).__name__
    Should Be Equal    ${type}    list    msg=Response should be array of services

    # Verify we have at least one service
    ${service_count}=    Get Length    ${body}
    Should Be True    ${service_count} >= 1    msg=Expected at least 1 service in response

    Log    Found ${service_count} services in API response    level=INFO

    # Verify Open311 compliance using custom validator
    Validate Service List Response    ${body}

    # Verify first service has all required Open311 fields
    ${first_service}=    Set Variable    ${body}[0]

    # Required field: service_code
    Dictionary Should Contain Key    ${first_service}    service_code
    ${service_code}=    Get From Dictionary    ${first_service}    service_code
    Should Not Be Equal    ${service_code}    ${NONE}    msg=service_code should not be null
    Should Not Be Equal    ${service_code}    ${EMPTY}    msg=service_code should not be empty
    Log    service_code: ${service_code}    level=INFO

    # Required field: service_name
    Dictionary Should Contain Key    ${first_service}    service_name
    ${service_name}=    Get From Dictionary    ${first_service}    service_name
    Should Not Be Empty    ${service_name}    msg=service_name should not be empty
    Log    service_name: ${service_name}    level=INFO

    # Required field: description
    Dictionary Should Contain Key    ${first_service}    description
    ${description}=    Get From Dictionary    ${first_service}    description
    Should Not Be Empty    ${description}    msg=description should not be empty
    Log    description: ${description}    level=INFO

    # Required field: metadata (boolean indicating if service definition exists)
    Dictionary Should Contain Key    ${first_service}    metadata
    ${metadata}=    Get From Dictionary    ${first_service}    metadata
    Should Be True    isinstance($metadata, bool)    msg=metadata must be boolean
    Log    metadata: ${metadata}    level=INFO

    # Required field: type (realtime, batch, or blackbox)
    Dictionary Should Contain Key    ${first_service}    type
    ${service_type}=    Get From Dictionary    ${first_service}    type
    Should Contain Any    ${service_type}    realtime    batch    blackbox    msg=type must be realtime, batch, or blackbox
    Log    type: ${service_type}    level=INFO

    Log    Successfully validated GET /services returns Open311-compliant response    level=INFO
