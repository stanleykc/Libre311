*** Settings ***
Documentation    API keywords for Libre311 Open311 acceptance tests
...              Provides REST API interaction and validation
Library          REST    ${API_BASE_URL}    ssl_verify=False
Library          Collections
Library          BuiltIn
Resource         ../variables/environments.robot
Resource         ../variables/test_data.robot

*** Keywords ***
Call GET Services
    [Documentation]    Call GET /services endpoint and return response
    [Arguments]    ${jurisdiction_id}=${JURISDICTION_ID}
    GET    /services?jurisdiction_id=${jurisdiction_id}
    ${rest}=    Get Library Instance    REST
    ${ctx}=    Evaluate    $rest.instances[-1]
    ${status}=    Set Variable    ${ctx['response']['status']}
    ${body}=    Set Variable    ${ctx['response']['body']}
    RETURN    ${status}    ${body}

Call GET Service Definition
    [Documentation]    Call GET /services/{service_code} endpoint
    [Arguments]    ${service_code}
    GET    /services/${service_code}
    ${status}=    Output    response status
    ${body}=    Output    response body
    RETURN    ${status}    ${body}

Call GET Requests
    [Documentation]    Call GET /requests endpoint with optional filters
    [Arguments]    ${service_code}=${EMPTY}    ${status}=${EMPTY}    ${start_date}=${EMPTY}    ${end_date}=${EMPTY}
    ${params}=    Create Dictionary
    Run Keyword If    '${service_code}' != ''    Set To Dictionary    ${params}    service_code=${service_code}
    Run Keyword If    '${status}' != ''    Set To Dictionary    ${params}    status=${status}
    Run Keyword If    '${start_date}' != ''    Set To Dictionary    ${params}    start_date=${start_date}
    Run Keyword If    '${end_date}' != ''    Set To Dictionary    ${params}    end_date=${end_date}
    GET    /requests
    ${response_status}=    Output    response status
    ${body}=    Output    response body
    RETURN    ${response_status}    ${body}

Call GET Request By ID
    [Documentation]    Call GET /requests/{service_request_id} endpoint
    [Arguments]    ${request_id}
    GET    /requests/${request_id}
    ${status}=    Output    response status
    ${body}=    Output    response body
    RETURN    ${status}    ${body}

Call POST Request
    [Documentation]    Call POST /requests to create new service request
    [Arguments]    ${service_code}    ${lat}    ${lng}    ${address}    ${description}    ${contact_name}=${EMPTY}    ${contact_email}=${EMPTY}    ${contact_phone}=${EMPTY}
    ${request_body}=    Create Dictionary
    ...    service_code=${service_code}
    ...    lat=${lat}
    ...    long=${lng}
    ...    address_string=${address}
    ...    description=${description}
    Run Keyword If    '${contact_name}' != ''    Set To Dictionary    ${request_body}    first_name=${contact_name}
    Run Keyword If    '${contact_email}' != ''    Set To Dictionary    ${request_body}    email=${contact_email}
    Run Keyword If    '${contact_phone}' != ''    Set To Dictionary    ${request_body}    phone=${contact_phone}

    POST    /requests    ${request_body}
    ${status}=    Output    response status
    ${body}=    Output    response body
    RETURN    ${status}    ${body}

Call GET Discovery
    [Documentation]    Call GET /discovery endpoint for Open311 service discovery
    GET    /discovery
    ${status}=    Output    response status
    ${body}=    Output    response body
    RETURN    ${status}    ${body}

Verify Open311 Response Format
    [Documentation]    Verify response conforms to Open311 GeoReport v2 format
    [Arguments]    ${endpoint_type}    ${body}
    # Verify response is valid JSON
    Should Not Be Empty    ${body}

    # Type-specific validation
    Run Keyword If    '${endpoint_type}' == 'services'    Verify Services Response Format    ${body}
    ...    ELSE IF    '${endpoint_type}' == 'service_definition'    Verify Service Definition Format    ${body}
    ...    ELSE IF    '${endpoint_type}' == 'requests'    Verify Requests Response Format    ${body}
    ...    ELSE IF    '${endpoint_type}' == 'request'    Verify Request Response Format    ${body}
    ...    ELSE IF    '${endpoint_type}' == 'discovery'    Verify Discovery Format    ${body}

Verify Services Response Format
    [Documentation]    Verify GET /services response has required Open311 fields
    [Arguments]    ${body}
    # Response should be array
    ${type}=    Evaluate    type($body).__name__
    Should Be Equal    ${type}    list    Response should be array

    # Check first service has required fields
    ${service}=    Set Variable    ${body}[0]
    Dictionary Should Contain Key    ${service}    service_code
    Dictionary Should Contain Key    ${service}    service_name
    Dictionary Should Contain Key    ${service}    description
    Dictionary Should Contain Key    ${service}    metadata
    Dictionary Should Contain Key    ${service}    type

Verify Service Definition Format
    [Documentation]    Verify GET /services/{code} response format
    [Arguments]    ${body}
    Dictionary Should Contain Key    ${body}    service_code
    Dictionary Should Contain Key    ${body}    attributes

Verify Requests Response Format
    [Documentation]    Verify GET /requests response is array
    [Arguments]    ${body}
    ${type}=    Evaluate    type($body).__name__
    Should Be Equal    ${type}    list    Response should be array

Verify Request Response Format
    [Documentation]    Verify GET /requests/{id} response has required fields
    [Arguments]    ${body}
    # Response should be array even for single request
    ${type}=    Evaluate    type($body).__name__
    Should Be Equal    ${type}    list    Response should be array

    # Check request has required fields
    ${request}=    Set Variable    ${body}[0]
    Dictionary Should Contain Key    ${request}    service_request_id
    Dictionary Should Contain Key    ${request}    status
    Dictionary Should Contain Key    ${request}    service_code
    Dictionary Should Contain Key    ${request}    description
    Dictionary Should Contain Key    ${request}    requested_datetime

Verify Discovery Format
    [Documentation]    Verify GET /discovery response format
    [Arguments]    ${body}
    Dictionary Should Contain Key    ${body}    changeset
    Dictionary Should Contain Key    ${body}    contact
    Dictionary Should Contain Key    ${body}    endpoints

Extract Request ID From Response
    [Documentation]    Extract service_request_id from POST /requests response
    [Arguments]    ${body}
    # Response is array, get first element
    ${request}=    Set Variable    ${body}[0]
    ${request_id}=    Get From Dictionary    ${request}    service_request_id
    RETURN    ${request_id}

Verify API Response Status
    [Documentation]    Verify HTTP status code matches expected
    [Arguments]    ${actual_status}    ${expected_status}
    Should Be Equal As Numbers    ${actual_status}    ${expected_status}    Expected status ${expected_status} but got ${actual_status}
