*** Settings ***
Documentation    Static test data for Libre311 acceptance tests
...              Sample addresses, service codes, and realistic citizen data

*** Variables ***
# Service Type Codes (from data-model.md)
${SERVICE_CODE_POTHOLE}         POTHOLE
${SERVICE_CODE_STREETLIGHT}     STREETLIGHT
${SERVICE_CODE_GRAFFITI}        GRAFFITI

# Service Names
${SERVICE_NAME_POTHOLE}         Pothole
${SERVICE_NAME_STREETLIGHT}     Broken Streetlight
${SERVICE_NAME_GRAFFITI}        Graffiti Removal

# Service Categories
${CATEGORY_STREETS}             Streets & Roads
${CATEGORY_SAFETY}              Public Safety
${CATEGORY_VANDALISM}           Vandalism

# Test Jurisdiction (Minneapolis area)
${JURISDICTION_NAME}            Minneapolis Test Area
${JURISDICTION_MIN_LAT}         44.9000
${JURISDICTION_MAX_LAT}         45.0500
${JURISDICTION_MIN_LNG}         -93.3290
${JURISDICTION_MAX_LNG}         -93.1990

# Sample Addresses (Minneapolis area - realistic coordinates)
${TEST_ADDRESS_1}               123 Main St, Minneapolis, MN 55401
${TEST_LAT_1}                   44.9778
${TEST_LNG_1}                   -93.2650

${TEST_ADDRESS_2}               456 Oak Ave, Minneapolis, MN 55403
${TEST_LAT_2}                   44.9830
${TEST_LNG_2}                   -93.2689

${TEST_ADDRESS_3}               789 Elm Blvd, Minneapolis, MN 55404
${TEST_LAT_3}                   44.9750
${TEST_LNG_3}                   -93.2700

# Out of Bounds Addresses (for negative testing)
${OUT_OF_BOUNDS_ADDRESS}        100 State St, St Paul, MN 55101
${OUT_OF_BOUNDS_LAT}            44.9537
${OUT_OF_BOUNDS_LNG}            -93.0900

# Sample Contact Information (realistic test data)
${TEST_CONTACT_NAME_1}          Jennifer Martinez
${TEST_CONTACT_EMAIL_1}         jennifer.martinez@example.com
${TEST_CONTACT_PHONE_1}         +1-612-555-0123

${TEST_CONTACT_NAME_2}          Michael Chen
${TEST_CONTACT_EMAIL_2}         m.chen@example.com
${TEST_CONTACT_PHONE_2}         +1-612-555-0456

${TEST_CONTACT_NAME_3}          Alice Johnson
${TEST_CONTACT_EMAIL_3}         alice.johnson@example.com
${TEST_CONTACT_PHONE_3}         +1-612-555-0789

# Sample Service Request Descriptions
${POTHOLE_DESCRIPTION}          Large pothole approximately 2 feet wide and 6 inches deep on eastbound lane near intersection. Causing vehicles to swerve into adjacent lane.
${STREETLIGHT_DESCRIPTION}      Streetlight has been out for 3 days. Area is very dark at night creating safety concern for pedestrians.
${GRAFFITI_DESCRIPTION}         Graffiti spray painted on building wall facing Main Street. Approximately 4 feet wide and 3 feet tall.

# Request Status Values (per Open311 spec)
${STATUS_NEW}                   new
${STATUS_OPEN}                  open
${STATUS_IN_PROGRESS}           in_progress
${STATUS_RESOLVED}              resolved
${STATUS_CLOSED}                closed

# Image File Names (test assets)
${IMAGE_POTHOLE}                pothole_sample_1.jpg
${IMAGE_STREETLIGHT}            streetlight_broken.jpg
${IMAGE_GRAFFITI}               graffiti_sample.jpg
${IMAGE_HUGE}                   huge_image.jpg
${IMAGE_INAPPROPRIATE}          inappropriate_content.jpg
${FILE_DOCUMENT}                document.pdf

# Size Limits
${MAX_IMAGE_SIZE_MB}            10
${MAX_DESCRIPTION_LENGTH}       1000
${MIN_DESCRIPTION_LENGTH}       10

# Test User Data (for authenticated tests)
${TEST_USER_EMAIL_1}            alice.johnson@example.com
${TEST_USER_NAME_1}             Alice Johnson
${TEST_USER_ID_1}               test-user-001

${TEST_USER_EMAIL_2}            bob.williams@example.com
${TEST_USER_NAME_2}             Bob Williams
${TEST_USER_ID_2}               test-user-002

# Open311 Required Fields
@{OPEN311_SERVICE_REQUIRED}     service_code    service_name    description    metadata    type
@{OPEN311_REQUEST_REQUIRED}     service_request_id    status    service_code    description    requested_datetime

# Test Data Markers
${TEST_DATA_MARKER}             created_for_testing
