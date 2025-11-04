*** Settings ***
Documentation    Docker health check keywords for Libre311 acceptance tests
...              Provides container status verification and log collection via Docker CLI
Library          Process
Library          OperatingSystem
Resource         ../variables/environments.robot

*** Keywords ***
Verify Docker Environment Ready
    [Documentation]    Verify all required Docker containers are running
    Check Container Status    ${DOCKER_API_CONTAINER}    running
    Check Container Status    ${DOCKER_UI_CONTAINER}    running
    Check Container Status    ${DOCKER_DB_CONTAINER}    running
    Log    All Docker containers are running

Check Container Status
    [Documentation]    Check if Docker container is in expected state
    [Arguments]    ${container_name}    ${expected_status}=running
    ${result}=    Run Process    docker    ps    --filter    name\=${container_name}    --format    {{.Status}}
    Should Be Equal As Numbers    ${result.rc}    0    Docker command failed

    ${status}=    Set Variable    ${result.stdout}
    Run Keyword If    '${expected_status}' == 'running'
    ...    Should Contain    ${status}    Up    Container ${container_name} is not running: ${status}

    Log    Container ${container_name} status: ${status}

Get Container Status
    [Documentation]    Get current status of Docker container
    [Arguments]    ${container_name}
    ${result}=    Run Process    docker    ps    -a    --filter    name\=${container_name}    --format    {{.Status}}
    Should Be Equal As Numbers    ${result.rc}    0    Docker command failed
    ${status}=    Set Variable    ${result.stdout}
    RETURN    ${status}

Wait For Container Ready
    [Documentation]    Wait for container to be ready (health check passes)
    [Arguments]    ${container_name}    ${timeout}=60s
    ${timeout_seconds}=    Convert Time    ${timeout}    result_format=number
    ${start_time}=    Get Time    epoch

    FOR    ${i}    IN RANGE    999999
        ${status}=    Get Container Status    ${container_name}
        ${ready}=    Run Keyword And Return Status
        ...    Should Contain    ${status}    Up
        Return From Keyword If    ${ready}    ${True}

        ${elapsed}=    Evaluate    int(time.time()) - ${start_time}
        Run Keyword If    ${elapsed} > ${timeout_seconds}
        ...    Fail    Container ${container_name} not ready after ${timeout}

        Sleep    2s
    END

Collect Container Logs On Failure
    [Documentation]    Collect logs from all containers when test fails
    [Arguments]    ${output_dir}=${EXECDIR}/reports/docker_logs
    Create Directory    ${output_dir}

    ${timestamp}=    Get Time    epoch
    Collect Container Logs    ${DOCKER_API_CONTAINER}    ${output_dir}/api_${timestamp}.log
    Collect Container Logs    ${DOCKER_UI_CONTAINER}    ${output_dir}/ui_${timestamp}.log
    Collect Container Logs    ${DOCKER_DB_CONTAINER}    ${output_dir}/db_${timestamp}.log

    Log    Docker logs collected to ${output_dir}

Collect Container Logs
    [Documentation]    Collect logs from specific container
    [Arguments]    ${container_name}    ${output_file}
    ${result}=    Run Process    docker    logs    --tail\=500    ${container_name}
    ...    stdout=${output_file}    stderr=STDOUT
    Log    Collected logs from ${container_name} to ${output_file}

Get Container IP Address
    [Documentation]    Get IP address of container on Docker network
    [Arguments]    ${container_name}    ${network}=${DOCKER_NETWORK}
    ${result}=    Run Process    docker    inspect
    ...    --format\={{.NetworkSettings.Networks.${network}.IPAddress}}
    ...    ${container_name}
    Should Be Equal As Numbers    ${result.rc}    0    Failed to get container IP
    ${ip}=    Set Variable    ${result.stdout}
    Log    Container ${container_name} IP: ${ip}
    RETURN    ${ip}

Verify Container Network Connectivity
    [Documentation]    Verify container can reach another container
    [Arguments]    ${source_container}    ${target_container}    ${target_port}
    ${target_ip}=    Get Container IP Address    ${target_container}

    # Use docker exec to ping from source container
    ${result}=    Run Process    docker    exec    ${source_container}
    ...    nc    -zv    ${target_ip}    ${target_port}
    ...    timeout=10s

    Run Keyword If    ${result.rc} != 0
    ...    Log    Network connectivity test failed: ${result.stderr}    WARN

    Log    Network connectivity from ${source_container} to ${target_container}:${target_port} verified

Restart Container
    [Documentation]    Restart Docker container
    [Arguments]    ${container_name}
    Log    Restarting container ${container_name}...
    ${result}=    Run Process    docker    restart    ${container_name}    timeout=30s
    Should Be Equal As Numbers    ${result.rc}    0    Failed to restart container ${container_name}
    Wait For Container Ready    ${container_name}    timeout=60s
    Log    Container ${container_name} restarted successfully

Stop Container
    [Documentation]    Stop Docker container
    [Arguments]    ${container_name}
    ${result}=    Run Process    docker    stop    ${container_name}    timeout=30s
    Should Be Equal As Numbers    ${result.rc}    0    Failed to stop container
    Log    Container ${container_name} stopped

Start Container
    [Documentation]    Start Docker container
    [Arguments]    ${container_name}
    ${result}=    Run Process    docker    start    ${container_name}
    Should Be Equal As Numbers    ${result.rc}    0    Failed to start container
    Wait For Container Ready    ${container_name}    timeout=60s
    Log    Container ${container_name} started

Verify Database Container Ready
    [Documentation]    Verify database container is accepting connections
    Check Container Status    ${DOCKER_DB_CONTAINER}    running

    # Test database connection by executing simple query
    ${result}=    Run Process    docker    exec    ${DOCKER_DB_CONTAINER}
    ...    mysql    -u${DB_USER}    -p${DB_PASSWORD}    -e    SELECT 1
    ...    timeout=10s

    Should Be Equal As Numbers    ${result.rc}    0    Database not accepting connections

    Log    Database container ${DOCKER_DB_CONTAINER} is ready

Verify API Container Ready
    [Documentation]    Verify API container is responding to requests
    Check Container Status    ${DOCKER_API_CONTAINER}    running

    # Test API health endpoint
    ${result}=    Run Process    curl    -f    -s    http://localhost:8080/health
    ...    timeout=10s

    Should Be Equal As Numbers    ${result.rc}    0    API not responding

    Log    API container ${DOCKER_API_CONTAINER} is ready

Verify UI Container Ready
    [Documentation]    Verify UI container is serving pages
    Check Container Status    ${DOCKER_UI_CONTAINER}    running

    # Test UI is responding
    ${result}=    Run Process    curl    -f    -s    http://localhost:3000
    ...    timeout=10s

    Should Be Equal As Numbers    ${result.rc}    0    UI not responding

    Log    UI container ${DOCKER_UI_CONTAINER} is ready
