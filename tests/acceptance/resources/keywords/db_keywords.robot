*** Settings ***
Documentation    Database keywords for Libre311 acceptance tests
...              Provides database connection, seeding, and cleanup functionality
Library          DatabaseLibrary
Resource         ../variables/environments.robot
Resource         ../variables/test_data.robot

*** Keywords ***
Connect To Test Database
    [Documentation]    Connect to Libre311 test database using pymysql
    [Arguments]    ${alias}=libre311_db
    Connect To Database
    ...    ${DB_MODULE}
    ...    ${DB_NAME}
    ...    ${DB_USER}
    ...    ${DB_PASSWORD}
    ...    ${DB_HOST}
    ...    ${DB_PORT}
    ...    alias=${alias}
    Log    Connected to database ${DB_NAME} at ${DB_HOST}:${DB_PORT}

Disconnect From Test Database
    [Documentation]    Close database connection
    [Arguments]    ${alias}=libre311_db
    Disconnect From Database    alias=${alias}

Seed Service Types
    [Documentation]    Insert test service types into database
    [Arguments]    ${mark_as_test}=True
    ${marker}=    Set Variable If    ${mark_as_test}    , ${TEST_DATA_MARKER}    ${EMPTY}

    # Insert Pothole service type
    Execute Sql String
    ...    INSERT INTO services (service_code, service_name, description, category, keywords${marker})
    ...    VALUES ('${SERVICE_CODE_POTHOLE}', '${SERVICE_NAME_POTHOLE}', 'Report potholes or damaged road surfaces', '${CATEGORY_STREETS}', 'road,street,asphalt,pavement'${marker})
    ...    ON DUPLICATE KEY UPDATE service_name=VALUES(service_name)

    # Insert Streetlight service type
    Execute Sql String
    ...    INSERT INTO services (service_code, service_name, description, category, keywords${marker})
    ...    VALUES ('${SERVICE_CODE_STREETLIGHT}', '${SERVICE_NAME_STREETLIGHT}', 'Report malfunctioning or dark streetlights', '${CATEGORY_SAFETY}', 'light,lamp,dark,safety'${marker})
    ...    ON DUPLICATE KEY UPDATE service_name=VALUES(service_name)

    # Insert Graffiti service type
    Execute Sql String
    ...    INSERT INTO services (service_code, service_name, description, category, keywords${marker})
    ...    VALUES ('${SERVICE_CODE_GRAFFITI}', '${SERVICE_NAME_GRAFFITI}', 'Report graffiti on public property', '${CATEGORY_VANDALISM}', 'vandalism,tagging,spray paint'${marker})
    ...    ON DUPLICATE KEY UPDATE service_name=VALUES(service_name)

    Log    Seeded 3 service types

Seed Service Definitions
    [Documentation]    Insert test service definitions into database
    [Arguments]    ${mark_as_test}=True
    ${marker}=    Set Variable If    ${mark_as_test}    , ${TEST_DATA_MARKER}    ${EMPTY}

    # Insert Pothole - Road definition
    Execute Sql String
    ...    INSERT INTO service_definitions (definition_code, service_code, definition_name, required_fields, expected_response_time${marker})
    ...    VALUES ('POTHOLE_ROAD', '${SERVICE_CODE_POTHOLE}', 'Pothole - Road', 'location,description,size_estimate', '48 hours'${marker})
    ...    ON DUPLICATE KEY UPDATE definition_name=VALUES(definition_name)

    # Insert Pothole - Sidewalk definition
    Execute Sql String
    ...    INSERT INTO service_definitions (definition_code, service_code, definition_name, required_fields, expected_response_time${marker})
    ...    VALUES ('POTHOLE_SIDEWALK', '${SERVICE_CODE_POTHOLE}', 'Pothole - Sidewalk', 'location,description', '72 hours'${marker})
    ...    ON DUPLICATE KEY UPDATE definition_name=VALUES(definition_name)

    Log    Seeded 2 service definitions

Seed Sample Requests
    [Documentation]    Insert sample service requests for testing view/filter functionality
    [Arguments]    ${count}=20    ${mark_as_test}=True
    ${marker}=    Set Variable If    ${mark_as_test}    , ${TEST_DATA_MARKER}    ${EMPTY}

    # Insert sample request 1 - Open Pothole
    Execute Sql String
    ...    INSERT INTO service_requests (service_code, latitude, longitude, address, description, contact_name, contact_email, contact_phone, status, submitted_date${marker})
    ...    VALUES ('${SERVICE_CODE_POTHOLE}', ${TEST_LAT_1}, ${TEST_LNG_1}, '${TEST_ADDRESS_1}', '${POTHOLE_DESCRIPTION}', '${TEST_CONTACT_NAME_1}', '${TEST_CONTACT_EMAIL_1}', '${TEST_CONTACT_PHONE_1}', '${STATUS_OPEN}', NOW()${marker})

    # Insert sample request 2 - Resolved Streetlight
    Execute Sql String
    ...    INSERT INTO service_requests (service_code, latitude, longitude, address, description, contact_name, contact_email, contact_phone, status, submitted_date${marker})
    ...    VALUES ('${SERVICE_CODE_STREETLIGHT}', ${TEST_LAT_2}, ${TEST_LNG_2}, '${TEST_ADDRESS_2}', '${STREETLIGHT_DESCRIPTION}', '${TEST_CONTACT_NAME_2}', '${TEST_CONTACT_EMAIL_2}', '${TEST_CONTACT_PHONE_2}', '${STATUS_RESOLVED}', DATE_SUB(NOW(), INTERVAL 3 DAY)${marker})

    # Insert sample request 3 - New Graffiti
    Execute Sql String
    ...    INSERT INTO service_requests (service_code, latitude, longitude, address, description, contact_name, contact_email, contact_phone, status, submitted_date${marker})
    ...    VALUES ('${SERVICE_CODE_GRAFFITI}', ${TEST_LAT_3}, ${TEST_LNG_3}, '${TEST_ADDRESS_3}', '${GRAFFITI_DESCRIPTION}', '${TEST_CONTACT_NAME_3}', '${TEST_CONTACT_EMAIL_3}', '${TEST_CONTACT_PHONE_3}', '${STATUS_NEW}', NOW()${marker})

    Log    Seeded 3 sample service requests

Clean Test Data
    [Documentation]    Delete all test data marked with created_for_testing flag
    Execute Sql String    DELETE FROM service_requests WHERE ${TEST_DATA_MARKER}
    Execute Sql String    DELETE FROM service_definitions WHERE ${TEST_DATA_MARKER}
    Execute Sql String    DELETE FROM services WHERE ${TEST_DATA_MARKER}
    Log    Cleaned all test data

Clean All Service Requests
    [Documentation]    Delete all service requests (use with caution)
    Execute Sql String    DELETE FROM service_requests
    Log    Deleted all service requests

Verify Database State
    [Documentation]    Verify database connection and basic schema
    ${result}=    Query    SELECT 1 as test
    Should Not Be Empty    ${result}
    Log    Database state verified

Get Service Request Count
    [Documentation]    Get total count of service requests
    [Arguments]    ${service_code}=${EMPTY}
    ${where}=    Set Variable If    '${service_code}' != ''    WHERE service_code='${service_code}'    ${EMPTY}
    @{result}=    Query    SELECT COUNT(*) as count FROM service_requests ${where}
    ${count}=    Set Variable    ${result[0][0]}
    RETURN    ${count}

Verify Service Type Exists
    [Documentation]    Verify service type exists in database
    [Arguments]    ${service_code}
    @{result}=    Query    SELECT service_code FROM services WHERE service_code='${service_code}'
    Should Not Be Empty    ${result}    Service type ${service_code} not found
    Log    Service type ${service_code} exists

Get Latest Request ID
    [Documentation]    Get the most recently created service request ID
    @{result}=    Query    SELECT service_request_id FROM service_requests ORDER BY submitted_date DESC LIMIT 1
    ${request_id}=    Set Variable    ${result[0][0]}
    RETURN    ${request_id}
