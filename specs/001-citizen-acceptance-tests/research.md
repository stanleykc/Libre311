# Research: Robot Framework Libraries for Citizen Acceptance Test Suite

**Feature**: Citizen Acceptance Test Suite | **Phase**: 0 (Research) | **Date**: 2025-11-04

## Overview

This document provides comprehensive research on Robot Framework libraries and dependencies suitable for building acceptance tests for the Libre311 Open311-compliant service request application. The test suite must validate citizen workflows across a 3-tier architecture (SvelteKit UI, Micronaut REST API, MySQL database) running in Docker containers.

## 1. Robot Framework Core

### Recommendation: Robot Framework 7.3.2

**Key Information**:
- **Latest Stable Version**: 7.3.2 (released July 4, 2025)
- **Python Compatibility**: Python 3.8 through 3.14
- **Python 3.11 Support**: Fully supported
- **Development Version**: 7.4 beta 1 available (October 7, 2025) - not recommended for production use

**Installation**:
```bash
python3 -m pip install robotframework==7.3.2
```

**Rationale**:
- Latest stable release with Python 3.14 support
- Mature ecosystem with extensive community support
- Native features for test organization, tagging, and parallel execution
- Built-in logging, reporting, and diagnostic capture capabilities
- Meets all performance and scalability requirements for the project

**Key Features Relevant to Project**:
- Variable type conversion for stronger typing
- Enhanced timeout handling
- Official Python 3.14 compatibility
- Robust error handling and diagnostics
- Tag-based test selection for CI/CD integration

**Breaking Changes from Earlier Versions**:
- Robot Framework 7.0 introduced variable type conversion (may affect existing tests if any)
- Enhanced error messages and stack traces
- Improved keyword naming conventions support

---

## 2. Browser Automation Library

### Recommendation: Robot Framework Browser Library 19.10.0

**Comparison Summary**:

| Feature | Browser Library (Playwright) | SeleniumLibrary |
|---------|----------------------------|-----------------|
| Technology | Playwright (modern) | Selenium WebDriver (established) |
| Performance | Faster, built-in auto-wait | Slower, explicit waits required |
| Headless Support | Native, optimized | Supported but less optimized |
| Screenshot Capture | Built-in, high quality | Built-in |
| Browser Support | Chromium, Firefox, WebKit | Chrome, Firefox, Edge, Safari |
| Network Interception | Yes (via Playwright) | No (limited via BrowserMob Proxy) |
| Shadow DOM Support | Automatic piercing | Manual handling required |
| Learning Curve | Steeper (new concepts) | Gentler (mature documentation) |
| Test Stability | Higher (auto-wait reduces flakiness) | Lower (more timing issues) |
| API Mocking | Native support | Requires external tools |

**Decision: Browser Library (Playwright-based)**

**Key Information**:
- **Latest Version**: 19.10.0 (released October 13, 2025)
- **Python Compatibility**: Python 3.10+ (meets our Python 3.11 requirement)
- **Robot Framework Compatibility**: Robot Framework 6.1+
- **Node.js Requirement**: Node 20/22/24 LTS
- **Playwright Version**: Tested with Playwright 1.56.0

**Installation**:
```bash
python3 -m pip install robotframework-browser==19.10.0
rfbrowser init
```

**Rationale for Browser Library over SeleniumLibrary**:
1. **Performance**: Significantly faster test execution due to built-in automatic waiting mechanism
2. **Modern Architecture**: Built on Playwright, which is actively developed and optimized for modern web applications (SvelteKit)
3. **Automatic Waiting**: Reduces flaky tests by automatically waiting for elements to be ready for interaction
4. **Network Interception**: Native support for mocking API calls and intercepting network requests (critical for mocking external services like UnityAuth, Google OAuth)
5. **Shadow DOM Support**: Automatic piercing of Shadow DOMs (important for modern web components)
6. **Better Error Messages**: More detailed and actionable error messages for debugging
7. **WebKit Support**: Can test against Safari-like WebKit engine in addition to Chrome/Firefox

**Key Features Relevant to Project**:
- Headless mode for CI/CD environments with headed mode for local debugging
- Built-in screenshot and video capture for test failures (meets Principle VI: Observable Execution)
- Network routing for mocking external API calls (UnityAuth, Google OAuth, SafeSearch)
- Automatic handling of async operations (important for SvelteKit's reactive UI)
- Viewport configuration for mobile/desktop testing
- Browser context isolation for parallel test execution
- Built-in assertion operators (==, !=, contains, etc.)

**Limitations to Consider**:
- Steeper learning curve compared to SeleniumLibrary
- Different keyword syntax from SeleniumLibrary (migration effort if team has Selenium experience)
- Smaller ecosystem of third-party extensions compared to Selenium
- Requires Node.js runtime in addition to Python

**Alternative Considered**: SeleniumLibrary 6.7.1
- **Pros**: More mature, larger community, gentler learning curve, no Node.js dependency
- **Cons**: Slower performance, no native network interception, manual handling of Shadow DOM, more test flakiness due to timing issues
- **Verdict**: Not recommended due to performance requirements (<5 min for P1 suite) and need for network mocking

**Browser Library Extensions**:
- `robotframework-browser-extensions`: Provides additional capabilities like network throttling and URL mocking
- Installation: `python3 -m pip install robotframework-browser-extensions`

---

## 3. API Testing Library

### Recommendation: RESTinstance 1.5.2

**Comparison Summary**:

| Feature | RESTinstance | RequestsLibrary |
|---------|--------------|-----------------|
| JSON Validation | JSON Schema (automatic) | Manual via JSONPath/assertions |
| Request Logging | Built-in, comprehensive | Via Robot Framework logging |
| OAuth Support | Standard HTTP auth headers | Standard HTTP auth headers |
| OpenAPI/Swagger | Native validation support | Manual implementation |
| JSON Path | Built-in selectors | Requires additional library |
| Schema Generation | Automatic from responses | Manual |
| Learning Curve | Moderate (schema-based) | Easy (direct HTTP calls) |
| Maintenance | Active (latest: April 2025) | Active (latest: Nov 2024) |

**Decision: RESTinstance**

**Key Information**:
- **Latest Version**: 1.5.2 (released April 11, 2025)
- **Python 3.11 Support**: Supported (active maintenance in 2024-2025)
- **Robot Framework Compatibility**: Requires Robot Framework 5.0+

**Installation**:
```bash
python3 -m pip install RESTinstance==1.5.2
```

**Rationale for RESTinstance over RequestsLibrary**:
1. **Open311 Compliance Validation**: RESTinstance can test requests and responses against OpenAPI 3.0 specs (critical for FR-017: Open311 GeoReport v2 compliance)
2. **Automatic JSON Schema Generation**: Generates JSON Schema from API responses, making it easier to validate response structure consistency
3. **Schema-Based Validation**: Validates based on constraints rather than specific values (e.g., "email must be valid" vs "email is foo@bar.com"), reducing test maintenance
4. **Built-in JSON Path Support**: Cleaner syntax for extracting and validating nested JSON data
5. **Minimal Programming Knowledge Required**: Relies on Robot Framework's language-agnostic syntax, easier for QA team members without deep programming background
6. **OpenAPI/Swagger Validation**: Native support for validating against OpenAPI 3.0 specs (can validate Open311 compliance)

**Key Features Relevant to Project**:
- Validates JSON responses against JSON Schema definitions
- Can test API contracts against OpenAPI/Swagger specifications
- Built-in support for JSONPath selectors for extracting values
- Request/response logging for diagnostics (Principle VI)
- Clean, readable syntax for API test scenarios
- Schema evolution tracking (schema becomes more accurate as tests run)

**Limitations to Consider**:
- Steeper learning curve than direct HTTP libraries if unfamiliar with JSON Schema
- Less direct control over HTTP request details compared to RequestsLibrary
- Smaller community compared to RequestsLibrary

**Alternative Considered**: RequestsLibrary (robotframework-requests)
- **Latest Stable**: 0.9.7 (April 7, 2024)
- **Latest Pre-release**: 1.0a14 (November 7, 2024)
- **Pros**: More direct HTTP control, larger user base, simpler for basic HTTP calls
- **Cons**: No native OpenAPI validation, more verbose test code, manual JSON schema validation
- **Verdict**: Not recommended due to lack of OpenAPI/Open311 compliance validation features

**Supporting Python Libraries**:
- `jsonschema`: For custom JSON Schema validation if needed
- `requests`: Underlying HTTP library (installed as RESTinstance dependency)

---

## 4. Database Library

### Recommendation: DatabaseLibrary 2.0.4 + pymysql

**Key Information**:
- **Latest Version**: 2.0.4 (active maintenance, Robocon 2024 update presentation)
- **Python 3.11 Support**: Supported
- **MySQL Driver**: pymysql (pure Python MySQL client)
- **Database API Spec**: Python Database API Specification 2.0 compliant

**Installation**:
```bash
python3 -m pip install robotframework-databaselibrary==2.0.4
python3 -m pip install pymysql==1.1.0
```

**Rationale**:
1. **Generic Database Support**: Single library works with multiple database types (MySQL, PostgreSQL, Oracle, SQLite) by swapping Python DB modules
2. **Standard DB API**: Uses Python DB API 2.0, making it compatible with most database drivers
3. **Active Maintenance**: Recent Robocon 2024 presentation indicates ongoing development and improvements
4. **Test Data Management**: Provides keywords for executing queries, validating data, and managing test data lifecycle
5. **Transaction Support**: Can execute queries in transactions for atomic test data setup/teardown
6. **Connection Pooling**: Supports multiple database connections with aliasing for complex scenarios

**Key Features Relevant to Project**:
- `Connect To Database` keyword with MySQL-specific parameters
- `Execute SQL String` for running seed data scripts or cleanup
- `Query` keyword for validating database state after API/UI operations
- `Row Count` and result validation keywords for test assertions
- Support for parameterized queries to prevent SQL injection in test data
- Transaction management for test isolation (Principle II)

**Example MySQL Connection**:
```robot
Connect To Database
    ...    pymysql
    ...    db_name=libre311_test
    ...    db_user=test_user
    ...    db_password=test_pass
    ...    db_host=127.0.0.1
    ...    db_port=3306
    ...    alias=libre311_db
```

**Alternative Considered**: MySQL-specific connector libraries
- **Pros**: More MySQL-specific optimizations, native MySQL features
- **Cons**: Less portable, harder to switch to PostgreSQL if needed, smaller Robot Framework community
- **Verdict**: Not recommended; generic DatabaseLibrary with pymysql provides better flexibility

**Supporting Libraries**:
- `pymysql==1.1.0`: Pure Python MySQL driver (recommended for Robot Framework)
- Alternative: `mysql-connector-python` (official MySQL driver, but heavier and less Robot Framework-friendly)

**Use Cases in Test Suite**:
1. **Test Data Seeding**: Insert service types, service definitions, and sample requests before test execution
2. **Test Isolation**: Clean up test data after each suite (DELETE or TRUNCATE)
3. **Database State Validation**: Verify that API calls correctly create/update database records (E2E validation per Principle I)
4. **Edge Case Testing**: Create specific database states for negative testing scenarios

---

## 5. Test Data Generation Library

### Recommendation: robotframework-faker 5.0.0

**Key Information**:
- **Latest Version**: 5.0.0 (released 2024, but no recent PyPI updates in past 12 months)
- **Status**: Maintenance status "Inactive" but widely used (42,140 weekly downloads)
- **Important Note**: Starting with version 6.0.0, Faker Python package version is no longer pinned—users must pin it manually
- **Python 3.11 Support**: Supported (Python 3.6+)

**Installation**:
```bash
python3 -m pip install robotframework-faker==5.0.0
python3 -m pip install Faker==30.8.2  # Pin specific Faker version for stability
```

**Rationale**:
1. **Realistic Test Data**: Generates realistic names, addresses, emails, phone numbers, descriptions (Principle IV)
2. **Robot Framework Integration**: Native keyword library with docstrings integrated into RIDE and libdoc
3. **Localization Support**: Can generate locale-specific data (important for address/phone format testing)
4. **Variety of Data Types**: Supports addresses, countries, emails, names, phone numbers, dates, text, and more
5. **Reproducible Data**: Can seed random generator for consistent test data across runs

**Key Features Relevant to Project**:
- `FakerLibrary.address`: Generate realistic street addresses for service request locations
- `FakerLibrary.email`: Generate valid email formats for contact information
- `FakerLibrary.first_name` / `FakerLibrary.last_name`: Generate realistic citizen names
- `FakerLibrary.phone_number`: Generate valid phone numbers
- `FakerLibrary.text`: Generate realistic descriptions for service requests
- `FakerLibrary.latitude` / `FakerLibrary.longitude`: Generate valid geographic coordinates

**Example Usage**:
```robot
*** Test Cases ***
Submit Service Request With Random Data
    ${name}=    FakerLibrary.Name
    ${email}=    FakerLibrary.Email
    ${address}=    FakerLibrary.Address
    ${phone}=    FakerLibrary.Phone Number
    ${description}=    FakerLibrary.Text    max_nb_chars=200
    Submit Request Form    ${name}    ${email}    ${address}    ${phone}    ${description}
```

**Limitations to Consider**:
- Maintenance status is "Inactive" (last update over 12 months ago)
- Version 6.0.0+ requires manual Faker version pinning
- Geographic coordinates may not correspond to real addresses (need custom validation for Open311 compliance)

**Alternative Considered**: Custom Python test data generator
- **Pros**: Full control, Open311-specific data generation, guaranteed realistic coordinate/address pairs
- **Cons**: Requires development time, maintenance burden
- **Recommendation**: Use robotframework-faker for most data, create custom TestDataGenerator.py library for Open311-specific needs (addresses with valid coordinates, service type codes)

**Supporting Libraries**:
- `Faker==30.8.2`: Underlying Python library (pin version for stability)

---

## 6. Docker Container Management Library

### Recommendation: robotframework-dockerlibrary

**Key Information**:
- **Library Name**: robotframework-dockerlibrary (also known as DockerLibrary)
- **Latest Version**: Check PyPI for current stable release
- **Capabilities**: Full Docker CLI command support, container lifecycle management, docker-in-docker

**Installation**:
```bash
python3 -m pip install robotframework-dockerlibrary
```

**Rationale**:
1. **Container Health Checks**: Verify Docker containers (libre311-api, libre311-ui-dev, libre311-db) are running before tests start
2. **Container Lifecycle**: Can start/stop/restart containers for specific test scenarios
3. **Docker-in-Docker**: Supports testing scenarios where containers spawn other containers
4. **Log Collection**: Retrieve container logs for diagnostics on test failure (Principle VI)
5. **Network Inspection**: Verify unity-network configuration and container connectivity

**Key Features Relevant to Project**:
- Container status verification (ensure all three tiers are healthy)
- Log retrieval for debugging failed tests
- Docker Compose integration (can work with docker-compose.local.yml)
- Health check validation before running test suites
- Container restart for cleanup between test runs

**Example Usage**:
```robot
*** Settings ***
Library    DockerLibrary

*** Test Cases ***
Verify Docker Environment Ready
    ${status}=    Get Container Status    libre311-api
    Should Be Equal    ${status}    running
    ${status}=    Get Container Status    libre311-ui-dev
    Should Be Equal    ${status}    running
    ${status}=    Get Container Status    libre311-db
    Should Be Equal    ${status}    running

Collect Logs On Failure
    [Teardown]    Run Keyword If Test Failed    Collect Container Logs

*** Keywords ***
Collect Container Logs
    ${api_logs}=    Get Container Logs    libre311-api
    Log    ${api_logs}
    ${ui_logs}=    Get Container Logs    libre311-ui-dev
    Log    ${ui_logs}
    ${db_logs}=    Get Container Logs    libre311-db
    Log    ${db_logs}
```

**Alternative Considered**: Direct Docker CLI via Bash
- **Pros**: No additional library dependency, direct control
- **Cons**: Less Robot Framework integration, harder to extract and validate output, less portable across OS
- **Verdict**: Use robotframework-dockerlibrary for better integration, fall back to Bash for complex scenarios

**Alternative Library**: robotframework-docker (by vogoltsov)
- Focuses on Docker Compose testing
- May be suitable if Docker Compose integration is primary need
- Less comprehensive than robotframework-dockerlibrary for general Docker management

---

## 7. Additional Supporting Libraries

### 7.1 Robot Framework Built-In Libraries

These libraries come with Robot Framework core installation and require no additional packages:

**BuiltIn Library** (robot.libraries.BuiltIn):
- Core logging keywords: `Log`, `Log To Console`
- Assertions: `Should Be Equal`, `Should Contain`, `Should Not Be Empty`
- Variable management and test flow control
- Time/date utilities for timestamp validation

**Collections Library**:
- List and dictionary manipulation for test data
- Useful for validating API response arrays and objects

**String Library**:
- String validation and manipulation
- Regex matching for validating formats (tracking numbers, email patterns)

**DateTime Library**:
- Timestamp validation for service request creation/update times
- Date range filtering test validation

**OperatingSystem Library**:
- File system operations for managing test resources (images, test data files)
- Environment variable access for configuration

### 7.2 Screenshot and Diagnostics

**robotframework-browser** (already recommended) includes:
- Built-in screenshot capture on failure
- Video recording capability for full test execution
- Browser console log capture
- Network traffic logging

**Additional diagnostic tools**:
- Robot Framework native `--loglevel DEBUG` for detailed execution logs
- `--outputdir` for organizing test reports
- `--timestampoutputs` for unique report names per execution

### 7.3 Parallel Execution

**Pabot** (Parallel executor for Robot Framework):
```bash
python3 -m pip install robotframework-pabot
```

**Features**:
- Parallel test execution across multiple processes
- Useful for running P1/P2/P3 suites in parallel
- Significant time savings for large test suites

**Usage**:
```bash
pabot --processes 3 tests/acceptance/suites/
```

---

## 8. Complete Dependency List

### Core Framework

```bash
# Core Robot Framework
python3 -m pip install robotframework==7.3.2
```

### Browser Automation

```bash
# Playwright-based browser automation
python3 -m pip install robotframework-browser==19.10.0
rfbrowser init  # Downloads Playwright browsers
```

### API Testing

```bash
# REST API testing with OpenAPI validation
python3 -m pip install RESTinstance==1.5.2
```

### Database Access

```bash
# Database testing and data management
python3 -m pip install robotframework-databaselibrary==2.0.4
python3 -m pip install pymysql==1.1.0
```

### Test Data Generation

```bash
# Realistic test data generation
python3 -m pip install robotframework-faker==5.0.0
python3 -m pip install Faker==30.8.2
```

### Docker Management

```bash
# Docker container lifecycle and diagnostics
python3 -m pip install robotframework-dockerlibrary
```

### Optional/Supporting

```bash
# Parallel test execution
python3 -m pip install robotframework-pabot

# JSON Schema validation (if custom validation needed beyond RESTinstance)
python3 -m pip install jsonschema
```

---

## 9. Technical Context Updates

Based on this research, the Technical Context section in `plan.md` should be updated:

**Language/Version**: Python 3.11+ (Robot Framework 7.3.2 requires Python 3.8+)

**Primary Dependencies**:
- Robot Framework 7.3.2 (core test framework)
- robotframework-browser 19.10.0 (Playwright-based browser automation)
- RESTinstance 1.5.2 (REST API testing with OpenAPI validation)
- robotframework-databaselibrary 2.0.4 + pymysql 1.1.0 (database access)
- robotframework-faker 5.0.0 + Faker 30.8.2 (test data generation)
- robotframework-dockerlibrary (container management)

**Testing**: Robot Framework with Browser Library (Playwright), RESTinstance (API), DatabaseLibrary (MySQL), and DockerLibrary (container orchestration)

---

## 10. Open Questions and Risks

### Open Questions

1. **Node.js Availability**: Does the CI/CD environment have Node.js 20/22/24 LTS available? Browser Library requires Node.js for Playwright runtime.
   - **Mitigation**: Verify CI environment or update Docker image to include Node.js

2. **Docker Socket Access**: Will test execution environment have access to Docker socket for container management?
   - **Mitigation**: If not, remove Docker container health checks from test prerequisites

3. **Open311 Schema Definition**: Is there an existing OpenAPI 3.0 spec for the Libre311 Open311 implementation?
   - **Mitigation**: If not, Phase 1 should create OpenAPI schema from Open311 GeoReport v2 specification

4. **External Service Mocking**: How will UnityAuth, Google OAuth, and SafeSearch API be mocked?
   - **Mitigation**: Use Browser Library's network routing for HTTP-level mocks, or mock at application level

### Risks

1. **Learning Curve for Browser Library**: Team may need training if coming from Selenium background
   - **Impact**: Medium | **Likelihood**: High
   - **Mitigation**: Allocate time for proof-of-concept and training; Browser Library's better documentation and examples offset learning curve

2. **RESTinstance Schema-Based Approach**: Schema-based validation may be unfamiliar to team
   - **Impact**: Low | **Likelihood**: Medium
   - **Mitigation**: Start with simple JSON Path assertions, gradually adopt schema validation

3. **robotframework-faker Maintenance Status**: Library marked as "inactive" on some sources
   - **Impact**: Low | **Likelihood**: Low
   - **Mitigation**: Faker (underlying library) is actively maintained; can create custom test data library if needed

4. **Performance Goals**: <5 minute P1 suite execution may be challenging with full E2E tests
   - **Impact**: High | **Likelihood**: Medium
   - **Mitigation**: Use Browser Library's parallel execution, optimize test data setup, consider headless mode optimizations

---

## 11. Next Steps (Phase 1 - Data Model & Contracts)

1. **Create Open311Validator.py**: Custom Python library to validate Open311 GeoReport v2 API compliance
2. **Define API Contracts**: Document expected request/response formats for all Open311 endpoints (GET /services, GET /requests, POST /requests)
3. **Define Test Data Model**: Specify realistic test data structure (service types, addresses with valid coordinates, sample requests)
4. **Create TestDataGenerator.py**: Custom library to generate Open311-compliant test data with realistic address/coordinate pairs
5. **Environment Setup Guide**: Document how to set up Python 3.11, Robot Framework, and all dependencies on developer machines
6. **Proof of Concept**: Create one simple test case using Browser Library + RESTinstance to validate setup and approach

---

## 12. References

### Official Documentation

- Robot Framework: https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html
- Robot Framework Browser Library: https://robotframework-browser.org/
- RESTinstance: https://asyrjasalo.github.io/RESTinstance/
- Database Library: https://github.com/MarketSquare/Robotframework-Database-Library
- Faker Library: https://github.com/MarketSquare/robotframework-faker
- Docker Library: https://github.com/testautomation/robotframework-dockerlibrary

### PyPI Package Pages

- robotframework: https://pypi.org/project/robotframework/
- robotframework-browser: https://pypi.org/project/robotframework-browser/
- RESTinstance: https://pypi.org/project/RESTinstance/
- robotframework-databaselibrary: https://pypi.org/project/robotframework-databaselibrary/
- robotframework-faker: https://pypi.org/project/robotframework-faker/
- robotframework-dockerlibrary: https://pypi.org/project/robotframework-dockerlibrary/

### Community Resources

- Robot Framework Forum: https://forum.robotframework.org/
- Browser Library vs Selenium Discussion: https://forum.robotframework.org/t/selenium-library-or-browser-library-in-robot-framework/2899
- Open311 GeoReport v2 Specification: http://wiki.open311.org/GeoReport_v2/

---

**Research Completed**: 2025-11-04
**Next Phase**: Phase 1 - Data Model & Contracts (data-model.md, quickstart.md, contracts/)
