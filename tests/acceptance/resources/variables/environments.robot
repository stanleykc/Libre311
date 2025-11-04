*** Settings ***
Documentation    Environment configuration for Libre311 acceptance tests
...              Default values work for local Docker environment

*** Variables ***
# API Configuration
${API_BASE_URL}             http://localhost:8080/api
${API_TIMEOUT}              30 seconds
${JURISDICTION_ID}          stlma

# UI Configuration
${UI_BASE_URL}              http://localhost:3000
${UI_TIMEOUT}               30 seconds

# Database Configuration
${DB_HOST}                  localhost
${DB_PORT}                  23306
${DB_USER}                  root
${DB_PASSWORD}              test
${DB_NAME}                  libre311
${DB_MODULE}                pymysql

# Browser Configuration
${BROWSER_MODE}             headless    # Change to 'headed' for debugging
${BROWSER_TYPE}             chromium
${DEFAULT_VIEWPORT_WIDTH}   1920
${DEFAULT_VIEWPORT_HEIGHT}  1080
${MOBILE_VIEWPORT_WIDTH}    375
${MOBILE_VIEWPORT_HEIGHT}   667

# Docker Configuration
${DOCKER_API_CONTAINER}     libre311-api
${DOCKER_UI_CONTAINER}      libre311-ui-dev
${DOCKER_DB_CONTAINER}      libre311-db
${DOCKER_NETWORK}           unity-network

# Test Execution Settings
${DEFAULT_TIMEOUT}          10 seconds
${LONG_TIMEOUT}             30 seconds
${SHORT_TIMEOUT}            5 seconds
${SCREENSHOT_ON_FAILURE}    True

# Test Data Markers
${TEST_DATA_FLAG}           created_for_testing=true
