# Quickstart: Running Citizen Acceptance Tests

**Purpose**: Step-by-step guide to set up and execute Robot Framework acceptance tests for Libre311

## Prerequisites

### Required Software
- **Python 3.11+**: Check with `python3 --version`
- **Node.js 20/22/24 LTS**: Required for Browser Library (Playwright)
  - Check with `node --version`
  - Install from https://nodejs.org/ or via package manager
- **Docker Desktop**: For running Libre311 services
  - Check with `docker --version` and `docker compose version`
- **Git**: For cloning repository

### System Requirements
- **Operating System**: macOS, Linux, or Windows (with WSL2 for best Docker performance)
- **RAM**: Minimum 8GB (16GB recommended for running all containers + browser tests)
- **Disk Space**: ~5GB for Docker images + test artifacts

## Installation Steps

### 1. Clone Repository and Check Out Feature Branch

```bash
# Clone the Libre311 repository
git clone https://github.com/UnityFoundation-io/Libre311.git
cd Libre311

# Check out the acceptance test feature branch
git checkout 001-citizen-acceptance-tests
```

### 2. Set Up Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv-acceptance-tests

# Activate virtual environment
# On macOS/Linux:
source venv-acceptance-tests/bin/activate
# On Windows:
venv-acceptance-tests\Scripts\activate

# Verify Python version
python --version  # Should show 3.11 or higher
```

### 3. Install Robot Framework and Dependencies

```bash
# Upgrade pip
python -m pip install --upgrade pip

# Install Robot Framework core
python -m pip install robotframework==7.3.2

# Install browser automation (requires Node.js)
python -m pip install robotframework-browser==19.10.0
rfbrowser init  # Downloads Playwright browsers (Chrome, Firefox, WebKit)

# Install API testing
python -m pip install RESTinstance==1.5.2

# Install database access
python -m pip install robotframework-databaselibrary==2.0.4
python -m pip install pymysql==1.1.0

# Install test data generation
python -m pip install robotframework-faker==5.0.0
python -m pip install Faker==30.8.2

# Install Docker management
python -m pip install robotframework-dockerlibrary

# Optional: Install parallel execution
python -m pip install robotframework-pabot
```

**Installation Verification**:
```bash
# Verify Robot Framework
robot --version  # Should show 7.3.2

# Verify Browser Library
python -c "from Browser import Browser; print('Browser Library OK')"

# Verify Node.js (required for Browser Library)
node --version  # Should show v20.x, v22.x, or v24.x
```

### 4. Configure Test Environment

```bash
# Copy environment template
cd tests/acceptance
cp resources/variables/environments.robot.example resources/variables/environments.robot

# Edit environment variables (if needed)
# Default values work for local Docker environment
```

**Default Environment Configuration** (`resources/variables/environments.robot`):
```robot
*** Variables ***
${API_BASE_URL}         http://localhost:8080/api
${UI_BASE_URL}          http://localhost:3000
${DB_HOST}              localhost
${DB_PORT}              23306
${DB_USER}              libre311user
${DB_PASSWORD}          libre311pass
${DB_NAME}              libre311db
${BROWSER_MODE}         headless    # Change to 'headed' for debugging
```

### 5. Start Libre311 Docker Environment

```bash
# Return to repository root
cd /path/to/Libre311

# Start all Libre311 services (API, UI, Database)
docker compose -f docker-compose.local.yml up -d

# Wait for services to be healthy (30-60 seconds)
# Check status
docker ps  # Should show libre311-api, libre311-ui-dev, libre311-db running

# Verify API is responding
curl http://localhost:8080/api/services  # Should return JSON

# Verify UI is responding
curl http://localhost:3000  # Should return HTML
```

**Health Check Commands**:
```bash
# Check API health
docker logs libre311-api | tail -20

# Check UI health
docker logs libre311-ui-dev | tail -20

# Check database health
docker exec libre311-db mysql -ulibre311user -plibre311pass -e "SELECT 1"
```

### 6. Seed Test Data

```bash
# Navigate to test setup directory
cd tests/acceptance/setup

# Run database seeding script
python seed_test_data.py

# Verify test data created
docker exec libre311-db mysql -ulibre311user -plibre311pass libre311db -e \
  "SELECT COUNT(*) FROM services WHERE created_for_testing = true"
```

**Note**: Test suites automatically seed and clean their own data during suite setup/teardown. Manual seeding is optional for development.

## Running Tests

### Run All Tests

```bash
cd tests/acceptance

# Run all test suites
robot suites/

# Expected output:
# ==============================================================================
# Suites
# ==============================================================================
# Suites.P1 Browse Services                                            | PASS |
# 4 tests, 4 passed, 0 failed
# ------------------------------------------------------------------------------
# Suites.P1 View Requests                                              | PASS |
# 6 tests, 6 passed, 0 failed
# ------------------------------------------------------------------------------
# ... (other suites)
# ==============================================================================
# Output:  /path/to/Libre311/tests/acceptance/reports/output.xml
# Log:     /path/to/Libre311/tests/acceptance/reports/log.html
# Report:  /path/to/Libre311/tests/acceptance/reports/report.html
```

### Run Specific Priority Level

```bash
# Run only P1 (critical) tests - fastest, for smoke testing
robot --include P1 suites/

# Run only P2 (standard) tests
robot --include P2 suites/

# Run only P3 (extended) tests
robot --include P3 suites/
```

### Run Specific User Story

```bash
# Run only browse services tests (User Story 1)
robot suites/P1_browse_services.robot

# Run only submit request tests (User Story 3)
robot suites/P2_submit_anonymous.robot
```

### Run by Tag

```bash
# Run only UI tests
robot --include ui suites/

# Run only API tests
robot --include api suites/

# Run only Open311 compliance tests
robot --include open311-compliance suites/

# Run smoke tests only (P1 + smoke tag)
robot --include P1ANDsmoke suites/
```

### Run in Headed Mode (for Debugging)

```bash
# Set browser to headed mode
export BROWSER_MODE=headed

# Run tests with visible browser
robot suites/P1_browse_services.robot

# Watch browser automation in real-time
```

### Run with Parallel Execution (Faster)

```bash
# Install pabot if not already installed
python -m pip install robotframework-pabot

# Run suites in parallel (4 processes)
pabot --processes 4 suites/

# Note: Each process gets isolated database schema per constitution principle II
```

### Run and Generate Custom Report

```bash
# Run with custom output directory
robot --outputdir reports/$(date +%Y%m%d_%H%M%S) suites/

# Generate report with custom name
robot --outputdir reports --output p1_results.xml --log p1_log.html --report p1_report.html --include P1 suites/
```

## Viewing Test Results

### HTML Reports

After test execution, three HTML files are generated in `tests/acceptance/reports/`:

1. **report.html**: High-level summary with pass/fail statistics, execution times
   - Open in browser: `open reports/report.html` (macOS) or `xdg-open reports/report.html` (Linux)

2. **log.html**: Detailed test execution log with screenshots, keyword details, timing
   - Shows every action taken during test execution
   - Includes screenshots on failure
   - Expandable/collapsible test steps

3. **output.xml**: Machine-readable XML for CI/CD integration

### Screenshots and Diagnostics

Failed tests automatically capture:
- **Screenshots**: Saved to `reports/browser/screenshot/*.png`
- **API Logs**: Saved to `reports/api_logs/*.json`
- **Database State**: Saved to `reports/db_dumps/*.sql` (if enabled)
- **Container Logs**: Saved to `reports/docker_logs/*.log`

View screenshot from failed test:
```bash
# Screenshots are linked in log.html
open reports/browser/screenshot/P1_browse_services-001.png
```

## Common Commands Cheat Sheet

```bash
# Quick smoke test (P1 only, ~5 minutes)
robot --include P1 --outputdir reports/smoke suites/

# Full regression test (P1+P2+P3, ~15 minutes)
robot --outputdir reports/regression suites/

# Rerun only failed tests from previous run
robot --rerunfailed reports/output.xml --outputdir reports/rerun suites/

# Run with verbose logging (for debugging)
robot --loglevel DEBUG --include P1 suites/

# Dry run (validate syntax without executing)
robot --dryrun suites/

# List all tests without running
robot --dryrun --loglevel TRACE suites/ | grep "Test Name"

# Run specific test by name
robot --test "Browse Available Service Types" suites/

# Run with custom variable override
robot --variable API_BASE_URL:http://192.168.1.100:8080 suites/
```

## Troubleshooting

### Browser Library Installation Issues

**Problem**: `rfbrowser init` fails with "Node.js not found"

**Solution**:
```bash
# Verify Node.js installation
node --version  # Should be v20.x, v22.x, or v24.x

# If not installed, install Node.js LTS from https://nodejs.org/
# Then retry
rfbrowser init
```

**Problem**: Browser download fails during `rfbrowser init`

**Solution**:
```bash
# Use specific browser only (faster)
rfbrowser init chromium

# Or with different download server
PLAYWRIGHT_DOWNLOAD_HOST=https://cdn.npmmirror.com rfbrowser init
```

### Docker Connection Issues

**Problem**: Tests fail with "Connection refused" to localhost:8080

**Solution**:
```bash
# Verify Docker containers are running
docker ps | grep libre311

# If not running, start them
docker compose -f docker-compose.local.yml up -d

# Check API logs for errors
docker logs libre311-api

# Verify API is accessible
curl http://localhost:8080/api/services
```

**Problem**: Tests fail with "Database connection error"

**Solution**:
```bash
# Check database container
docker ps | grep libre311-db

# Verify database credentials in environments.robot match docker-compose
# Check docker-compose.local.yml for DB_USER, DB_PASSWORD

# Test database connection manually
docker exec libre311-db mysql -ulibre311user -plibre311pass -e "SHOW DATABASES"
```

### Test Execution Issues

**Problem**: Tests fail with "No browser installed"

**Solution**:
```bash
# Reinstall browsers
rfbrowser init

# Or install specific browser
rfbrowser init chromium
```

**Problem**: Tests fail with "Element not found" or timeout errors

**Solution**:
```bash
# Run in headed mode to see what's happening
export BROWSER_MODE=headed
robot suites/P1_browse_services.robot

# Increase timeouts in environments.robot if UI is slow
# Add to environments.robot:
# ${DEFAULT_TIMEOUT}    30 seconds  # Increased from 10s
```

**Problem**: Database cleanup fails between tests

**Solution**:
```bash
# Manually clean test data
python tests/acceptance/setup/cleanup_test_data.py

# Or reset database
docker compose -f docker-compose.local.yml down
docker compose -f docker-compose.local.yml up -d
# Wait for Flyway migrations to complete
```

### Performance Issues

**Problem**: P1 tests take longer than 5 minutes

**Solution**:
1. Run in headless mode: `export BROWSER_MODE=headless`
2. Use parallel execution: `pabot --processes 4 suites/`
3. Reduce test data volume in `setup/seed_test_data.py`
4. Check Docker resource allocation (increase CPU/RAM in Docker Desktop settings)

**Problem**: Tests are flaky (intermittent failures)

**Solution**:
1. Check Browser Library auto-wait is enabled (default)
2. Add explicit waits for dynamic content: `Wait Until Element Is Visible`
3. Verify Docker containers are stable: `docker stats`
4. Check for resource constraints (RAM, CPU)

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/acceptance-tests.yml`:

```yaml
name: Acceptance Tests

on:
  pull_request:
    branches: [main]

jobs:
  acceptance-tests:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python 3.11
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Set up Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install robotframework==7.3.2
          pip install robotframework-browser==19.10.0
          pip install RESTinstance==1.5.2
          pip install robotframework-databaselibrary==2.0.4 pymysql==1.1.0
          pip install robotframework-faker==5.0.0 Faker==30.8.2
          pip install robotframework-dockerlibrary
          rfbrowser init chromium

      - name: Start Libre311 services
        run: |
          docker compose -f docker-compose.local.yml up -d
          sleep 30  # Wait for services to be ready

      - name: Run P1 smoke tests
        run: |
          cd tests/acceptance
          robot --include P1 --outputdir ../../reports/ci suites/

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-reports
          path: reports/ci/

      - name: Publish test results
        if: always()
        uses: EnricoMi/publish-unit-test-result-action@v2
        with:
          files: reports/ci/output.xml
```

### Running Tests in CI

```bash
# Quick smoke test for PR validation
robot --include P1ANDsmoke --outputdir reports/ci suites/

# Full regression for merge to main
robot --outputdir reports/ci suites/

# Generate JUnit-style XML for CI parsing
rebot --xunit junit.xml reports/output.xml
```

## Next Steps

1. **Review test logs**: Open `reports/log.html` to understand test execution
2. **Customize tests**: Modify `.robot` files in `suites/` to add scenarios
3. **Add keywords**: Create reusable keywords in `resources/keywords/`
4. **Extend Open311Validator**: Add validation logic in `resources/libraries/Open311Validator.py`
5. **Run in CI**: Integrate tests into GitHub Actions or other CI/CD pipeline

## Support and Documentation

- **Robot Framework Docs**: https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html
- **Browser Library Docs**: https://marketsquare.github.io/robotframework-browser/
- **RESTinstance Docs**: https://asyrjasalo.github.io/RESTinstance/
- **Open311 GeoReport v2**: http://wiki.open311.org/GeoReport_v2/
- **Libre311 README**: ../../README.md
- **Feature Spec**: spec.md
- **API Contracts**: contracts/open311_api_endpoints.md

## Quick Reference

| Command | Description |
|---------|-------------|
| `robot suites/` | Run all tests |
| `robot --include P1 suites/` | Run P1 (smoke) tests only |
| `robot --include api suites/` | Run API tests only |
| `robot --rerunfailed output.xml suites/` | Rerun failed tests |
| `pabot --processes 4 suites/` | Run in parallel (4 processes) |
| `robot --dryrun suites/` | Validate syntax only |
| `robot --loglevel DEBUG suites/` | Verbose debugging output |
| `open reports/log.html` | View detailed test execution log |
| `open reports/report.html` | View test summary report |

**Estimated Execution Times** (local Docker):
- P1 tests: ~5 minutes (smoke tests for PR validation)
- P1 + P2 tests: ~10 minutes (standard acceptance tests)
- P1 + P2 + P3 tests: ~15 minutes (full regression suite)

**Performance Tip**: Use parallel execution with `pabot` to reduce execution time by 50-70%:
```bash
pabot --processes 4 --outputdir reports/parallel suites/
```
