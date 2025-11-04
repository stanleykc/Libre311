*** Settings ***
Documentation    UI keywords for Libre311 acceptance tests
...              Provides browser automation and UI interaction
Library          Browser    timeout=${UI_TIMEOUT}    enable_playwright_debug=False
Resource         ../variables/environments.robot
Resource         ../variables/test_data.robot

*** Keywords ***
Open Libre311 UI
    [Documentation]    Open Libre311 UI in browser with configured settings
    [Arguments]    ${headless}=${BROWSER_MODE}
    ${headless_bool}=    Run Keyword If    '${headless}' == 'headless'    Set Variable    ${True}
    ...    ELSE    Set Variable    ${False}

    New Browser    ${BROWSER_TYPE}    headless=${headless_bool}
    New Context    viewport={'width': ${DEFAULT_VIEWPORT_WIDTH}, 'height': ${DEFAULT_VIEWPORT_HEIGHT}}
    New Page    ${UI_BASE_URL}
    Wait For Load State    networkidle    timeout=${UI_TIMEOUT}
    Log    Opened Libre311 UI at ${UI_BASE_URL}

Close Libre311 UI
    [Documentation]    Close browser and cleanup
    Close Browser

Navigate To Services Page
    [Documentation]    Navigate to the services/catalog page
    Click    text=Services
    Wait For Load State    networkidle
    ${url}=    Get Url
    Should Contain    ${url}    services
    Log    Navigated to Services page

Navigate To Requests Page
    [Documentation]    Navigate to the requests/map view page
    Click    text=Requests
    Wait For Load State    networkidle
    ${url}=    Get Url
    Should Contain    ${url}    requests
    Log    Navigated to Requests page

Navigate To Submit Request Form
    [Documentation]    Navigate to request submission form
    [Arguments]    ${service_code}=${EMPTY}
    Run Keyword If    '${service_code}' != ''    Click    text=${service_code}
    Click    text=Report Issue
    Wait For Load State    networkidle
    ${url}=    Get Url
    Should Contain    ${url}    submit
    Log    Navigated to Submit Request form

Fill Request Submission Form
    [Documentation]    Fill out service request submission form
    [Arguments]    ${service_code}    ${address}    ${description}    ${contact_name}=${EMPTY}    ${contact_email}=${EMPTY}    ${contact_phone}=${EMPTY}
    # Select service type
    Run Keyword If    '${service_code}' != ''    Select Options By    id=service-select    value    ${service_code}

    # Enter address
    Fill Text    id=address-input    ${address}
    Click    text=Search Address
    Wait For Elements State    id=location-confirmed    visible    timeout=5s

    # Enter description
    Fill Text    id=description-textarea    ${description}

    # Enter contact information if provided
    Run Keyword If    '${contact_name}' != ''    Fill Text    id=contact-name    ${contact_name}
    Run Keyword If    '${contact_email}' != ''    Fill Text    id=contact-email    ${contact_email}
    Run Keyword If    '${contact_phone}' != ''    Fill Text    id=contact-phone    ${contact_phone}

    Log    Filled request submission form

Submit Request Form
    [Documentation]    Click submit button and wait for confirmation
    Click    button:has-text("Submit Request")
    Wait For Load State    networkidle
    Wait For Elements State    text=Request submitted successfully    visible    timeout=10s
    Log    Submitted request form

Upload Image To Form
    [Documentation]    Upload image file to request submission form
    [Arguments]    ${image_path}
    ${absolute_path}=    Normalize Path    ${EXECDIR}/resources/test_images/${image_path}
    Upload File By Selector    input[type="file"]    ${absolute_path}
    Wait For Elements State    .image-preview    visible    timeout=5s
    Log    Uploaded image: ${image_path}

Verify Element Visible
    [Documentation]    Verify element is visible on page
    [Arguments]    ${selector}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait For Elements State    ${selector}    visible    timeout=${timeout}
    Log    Element visible: ${selector}

Verify Element Contains Text
    [Documentation]    Verify element contains expected text
    [Arguments]    ${selector}    ${expected_text}
    ${actual_text}=    Get Text    ${selector}
    Should Contain    ${actual_text}    ${expected_text}
    Log    Element ${selector} contains: ${expected_text}

Verify Service List Displayed
    [Documentation]    Verify service list/catalog is displayed
    Wait For Elements State    .service-list    visible    timeout=${UI_TIMEOUT}
    ${count}=    Get Element Count    .service-item
    Should Be True    ${count} > 0    No services displayed
    Log    Service list displayed with ${count} services

Verify Request Map Displayed
    [Documentation]    Verify request map view is displayed
    Wait For Elements State    #request-map    visible    timeout=${UI_TIMEOUT}
    Wait For Elements State    .map-marker    visible    timeout=${UI_TIMEOUT}
    ${count}=    Get Element Count    .map-marker
    Should Be True    ${count} > 0    No request markers on map
    Log    Request map displayed with ${count} markers

Click Request Marker
    [Documentation]    Click on a request marker on the map
    [Arguments]    ${marker_index}=1
    ${selector}=    Set Variable    .map-marker:nth-of-type(${marker_index})
    Click    ${selector}
    Wait For Elements State    .request-popup    visible    timeout=5s
    Log    Clicked request marker ${marker_index}

Verify Request Popup Displayed
    [Documentation]    Verify request detail popup is displayed
    [Arguments]    ${request_id}=${EMPTY}
    Wait For Elements State    .request-popup    visible    timeout=${DEFAULT_TIMEOUT}
    Run Keyword If    '${request_id}' != ''    Verify Element Contains Text    .request-popup    ${request_id}
    Log    Request popup displayed

Apply Service Type Filter
    [Documentation]    Apply service type filter on requests page
    [Arguments]    ${service_code}
    Select Options By    id=service-filter    value    ${service_code}
    Wait For Load State    networkidle
    Log    Applied service type filter: ${service_code}

Apply Status Filter
    [Documentation]    Apply status filter on requests page
    [Arguments]    ${status}
    Select Options By    id=status-filter    value    ${status}
    Wait For Load State    networkidle
    Log    Applied status filter: ${status}

Apply Date Range Filter
    [Documentation]    Apply date range filter on requests page
    [Arguments]    ${start_date}    ${end_date}
    Fill Text    id=start-date    ${start_date}
    Fill Text    id=end-date    ${end_date}
    Click    button:has-text("Apply Filters")
    Wait For Load State    networkidle
    Log    Applied date range filter: ${start_date} to ${end_date}

Switch To List View
    [Documentation]    Switch from map view to list view
    Click    button:has-text("List View")
    Wait For Elements State    .request-table    visible    timeout=${UI_TIMEOUT}
    Log    Switched to list view

Verify Request In List
    [Documentation]    Verify request appears in list view
    [Arguments]    ${request_id}
    ${selector}=    Set Variable    .request-table >> text=${request_id}
    Wait For Elements State    ${selector}    visible    timeout=${DEFAULT_TIMEOUT}
    Log    Request ${request_id} found in list

Capture Screenshot On Failure
    [Documentation]    Capture screenshot when test fails
    [Arguments]    ${screenshot_name}=failure
    ${timestamp}=    Get Time    epoch
    ${filename}=    Set Variable    ${EXECDIR}/reports/browser/screenshot/${screenshot_name}_${timestamp}.png
    Take Screenshot    ${filename}
    Log    Screenshot captured: ${filename}

Sign In With Google
    [Documentation]    Initiate Google OAuth sign in (mocked in tests)
    Click    button:has-text("Sign In")
    Wait For Load State    networkidle
    Log    Initiated Google OAuth sign in

Verify User Logged In
    [Documentation]    Verify user is logged in (name displayed)
    [Arguments]    ${user_name}
    Wait For Elements State    text=${user_name}    visible    timeout=${DEFAULT_TIMEOUT}
    Log    User ${user_name} is logged in

Navigate To Dashboard
    [Documentation]    Navigate to authenticated user dashboard
    Click    text=My Requests
    Wait For Load State    networkidle
    ${url}=    Get Url
    Should Contain    ${url}    dashboard
    Log    Navigated to user dashboard

Verify Dashboard Displays Requests
    [Documentation]    Verify dashboard shows user's requests
    [Arguments]    ${expected_count}
    Wait For Elements State    .dashboard-request-list    visible    timeout=${UI_TIMEOUT}
    ${count}=    Get Element Count    .dashboard-request-item
    Should Be Equal As Numbers    ${count}    ${expected_count}
    Log    Dashboard displays ${count} requests
