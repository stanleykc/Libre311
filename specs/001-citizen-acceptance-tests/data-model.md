# Data Model: Test Entities and Test Data

**Purpose**: Define test data structures, seeding strategies, and validation rules for acceptance tests

## Test Execution Entities

These entities represent test infrastructure, not application domain models.

### Test Suite
**Purpose**: Organizes test cases by priority and user story

**Attributes**:
- `suite_file`: Robot Framework .robot file name (e.g., `P1_browse_services.robot`)
- `priority`: P1 (critical), P2 (standard), P3 (extended)
- `user_story_id`: Maps to spec.md user story (US1-US5)
- `tags`: List of tags [priority, component, feature, type]
- `setup_keywords`: Keywords to run before suite (database seeding, Docker health check)
- `teardown_keywords`: Keywords to run after suite (database cleanup, log collection)
- `execution_timeout`: Maximum allowed execution time (P1: 5min, P2: 10min, P3: 15min)

**Validation Rules**:
- Suite file name must match pattern `P[1-3]_[domain].robot`
- All tests in suite must have same priority tag
- Setup must include database state verification
- Teardown must guarantee data cleanup

### Test Case
**Purpose**: Individual test scenario validating acceptance criteria

**Attributes**:
- `test_name`: Descriptive name in "Action Expected Outcome" format
- `tags`: Inherited from suite + specific tags (smoke, regression, open311-compliance)
- `setup_data`: Test-specific data requirements (service types, existing requests)
- `expected_outcome`: Observable result to verify
- `diagnostic_artifacts`: Screenshots, API logs, DB dumps on failure

**Validation Rules**:
- Test name must clearly describe user action and expected result
- Each test must be independently executable (no dependencies on other tests)
- Test must clean up any data it creates (idempotency requirement)

### Test Environment
**Purpose**: Configuration for Docker-based test execution

**Attributes**:
- `api_base_url`: http://libre311-api:8080 or http://localhost:8080
- `ui_base_url`: http://libre311-ui-dev:3000 or http://localhost:3000
- `db_connection_string`: mysql+pymysql://user:pass@libre311-db:3306/libre311db
- `docker_network`: unity-network
- `external_service_mocks`: URLs for mocked UnityAuth, Google OAuth, SafeSearch, ReCaptcha
- `browser_mode`: headless (CI/CD) or headed (local debugging)

**Validation Rules**:
- All services must pass health check before test execution
- Database schema must match Flyway migrations
- Mock services must respond to standard requests

## Application Test Data Entities

These mirror Libre311 application entities for test seeding.

### Service Type (Test Data)
**Purpose**: Seed data for available service categories citizens can report

**Attributes**:
- `service_code`: Unique identifier (e.g., "POTHOLE", "GRAFFITI")
- `service_name`: Display name (e.g., "Pothole", "Graffiti Removal")
- `description`: What this service covers
- `category`: Grouping (e.g., "Streets", "Parks", "Public Safety")
- `keywords`: Search terms

**Example Test Data**:
```python
service_types = [
    {
        "service_code": "POTHOLE",
        "service_name": "Pothole",
        "description": "Report potholes or damaged road surfaces",
        "category": "Streets & Roads",
        "keywords": ["road", "street", "asphalt", "pavement"]
    },
    {
        "service_code": "STREETLIGHT",
        "service_name": "Broken Streetlight",
        "description": "Report malfunctioning or dark streetlights",
        "category": "Public Safety",
        "keywords": ["light", "lamp", "dark", "safety"]
    },
    {
        "service_code": "GRAFFITI",
        "service_name": "Graffiti Removal",
        "description": "Report graffiti on public property",
        "category": "Vandalism",
        "keywords": ["vandalism", "tagging", "spray paint"]
    }
]
```

**Seeding Strategy**: Insert via API POST /services endpoint or direct database insert during suite setup

### Service Definition (Test Data)
**Purpose**: Subtypes of service types for more specific classification

**Attributes**:
- `definition_code`: Unique identifier within service type
- `service_code`: Parent service type
- `definition_name`: Specific subtype (e.g., "Pothole - Road", "Pothole - Sidewalk")
- `required_fields`: List of fields required for request submission
- `expected_response_time`: SLA in hours/days

**Example Test Data**:
```python
service_definitions = [
    {
        "definition_code": "POTHOLE_ROAD",
        "service_code": "POTHOLE",
        "definition_name": "Pothole - Road",
        "required_fields": ["location", "description", "size_estimate"],
        "expected_response_time": "48 hours"
    },
    {
        "definition_code": "POTHOLE_SIDEWALK",
        "service_code": "POTHOLE",
        "definition_name": "Pothole - Sidewalk",
        "required_fields": ["location", "description"],
        "expected_response_time": "72 hours"
    }
]
```

**Seeding Strategy**: Insert after service types, ensuring parent service_code exists

### Service Request (Test Data)
**Purpose**: Sample submitted requests for viewing/filtering tests

**Attributes**:
- `request_id`: Unique tracking number (generated by system)
- `service_code`: Service type
- `definition_code`: Service definition (optional)
- `latitude`: Geographic coordinate (realistic within test jurisdiction)
- `longitude`: Geographic coordinate (realistic within test jurisdiction)
- `address`: Street address matching coordinates
- `description`: Realistic issue description (100-500 characters)
- `contact_name`: Submitter name (realistic via Faker)
- `contact_email`: Submitter email (realistic via Faker)
- `contact_phone`: Submitter phone (realistic via Faker, E.164 format)
- `status`: new, open, in_progress, resolved, closed
- `submitted_date`: Timestamp
- `status_history`: List of status transitions with timestamps
- `images`: Optional list of image URLs/paths
- `staff_updates`: Optional list of staff comments with timestamps

**Example Test Data**:
```python
service_requests = [
    {
        "service_code": "POTHOLE",
        "definition_code": "POTHOLE_ROAD",
        "latitude": 44.9778,  # Minneapolis coordinates
        "longitude": -93.2650,
        "address": "123 Main St, Minneapolis, MN 55401",
        "description": "Large pothole approximately 2 feet wide and 6 inches deep on eastbound lane near intersection with 1st Ave. Causing vehicles to swerve into adjacent lane.",
        "contact_name": "Jennifer Martinez",
        "contact_email": "jennifer.martinez@example.com",
        "contact_phone": "+1-612-555-0123",
        "status": "open",
        "submitted_date": "2025-11-01T08:30:00Z",
        "images": ["pothole_123main_1.jpg"]
    },
    {
        "service_code": "STREETLIGHT",
        "latitude": 44.9830,
        "longitude": -93.2689,
        "address": "456 Oak Ave, Minneapolis, MN 55403",
        "description": "Streetlight has been out for 3 days. Area is very dark at night creating safety concern for pedestrians.",
        "contact_name": "Michael Chen",
        "contact_email": "m.chen@example.com",
        "contact_phone": "+1-612-555-0456",
        "status": "resolved",
        "submitted_date": "2025-10-28T19:45:00Z",
        "status_history": [
            {"status": "new", "timestamp": "2025-10-28T19:45:00Z"},
            {"status": "open", "timestamp": "2025-10-29T09:00:00Z"},
            {"status": "in_progress", "timestamp": "2025-10-30T14:30:00Z"},
            {"status": "resolved", "timestamp": "2025-10-31T16:00:00Z"}
        ],
        "staff_updates": [
            {"comment": "Work order created for electrical crew", "timestamp": "2025-10-29T09:00:00Z"},
            {"comment": "Crew dispatched to location", "timestamp": "2025-10-30T14:30:00Z"},
            {"comment": "Bulb replaced, light verified working", "timestamp": "2025-10-31T16:00:00Z"}
        ]
    }
]
```

**Seeding Strategy**:
- Create 20-30 sample requests per test suite
- Mix of statuses (40% open, 30% in_progress, 20% resolved, 10% closed)
- Geographic distribution across test jurisdiction boundaries
- Include requests with/without images, with/without staff updates
- Generate via TestDataGenerator.py using Faker for realistic names/emails/addresses

### Geographic Location (Test Data)
**Purpose**: Realistic coordinates and addresses for location-based testing

**Attributes**:
- `jurisdiction_name`: Test jurisdiction (e.g., "Minneapolis", "Test City")
- `boundary_polygon`: GeoJSON polygon defining service area
- `sample_addresses`: List of valid addresses within boundary
- `sample_coordinates`: List of (lat, lng) pairs within boundary
- `outside_addresses`: List of addresses outside boundary (for negative testing)

**Example Test Data**:
```python
test_jurisdiction = {
    "jurisdiction_name": "Minneapolis Test Area",
    "boundary_polygon": {
        "type": "Polygon",
        "coordinates": [[
            [-93.3290, 44.9000],
            [-93.3290, 45.0500],
            [-93.1990, 45.0500],
            [-93.1990, 44.9000],
            [-93.3290, 44.9000]
        ]]
    },
    "sample_addresses": [
        "123 Main St, Minneapolis, MN 55401",
        "456 Oak Ave, Minneapolis, MN 55403",
        "789 Elm Blvd, Minneapolis, MN 55404"
    ],
    "outside_addresses": [
        "100 State St, St Paul, MN 55101",  # Outside boundary
        "200 Lake St, Bloomington, MN 55420"  # Outside boundary
    ]
}
```

**Seeding Strategy**: Define single test jurisdiction with clear boundaries, generate addresses using Faker with coordinate validation

### Authentication Session (Test Data)
**Purpose**: Mock OAuth sessions for authenticated user testing

**Attributes**:
- `user_id`: Test user identifier
- `email`: Google OAuth email
- `name`: Full name from OAuth profile
- `oauth_token`: Mock JWT token
- `session_expiry`: Token expiration timestamp
- `submitted_requests`: List of request IDs submitted by this user

**Example Test Data**:
```python
test_users = [
    {
        "user_id": "test-user-001",
        "email": "alice.johnson@example.com",
        "name": "Alice Johnson",
        "oauth_token": "mock-jwt-token-abc123",
        "session_expiry": "2025-11-04T23:59:59Z",
        "submitted_requests": []  # Populated during test execution
    },
    {
        "user_id": "test-user-002",
        "email": "bob.williams@example.com",
        "name": "Bob Williams",
        "oauth_token": "mock-jwt-token-def456",
        "session_expiry": "2025-11-04T23:59:59Z",
        "submitted_requests": ["REQ-12345", "REQ-12346", "REQ-12347"]  # Pre-seeded requests
    }
]
```

**Seeding Strategy**: Mock OAuth responses via Browser Library network interception, seed user data in app_users table for authenticated scenarios

## Test Image Assets

**Purpose**: Pre-generated images for upload testing

**Attributes**:
- `valid_images`: List of JPEG/PNG files < 5MB, appropriate content
- `invalid_content_images`: Images that should trigger SafeSearch rejection
- `invalid_format_images`: Non-image files (PDF, TXT) for format validation
- `oversized_images`: Images > 5MB for size validation

**Storage Location**: `tests/acceptance/resources/test_images/`

**Example Files**:
- `pothole_sample_1.jpg` (500KB, valid pothole photo)
- `streetlight_broken.jpg` (800KB, valid streetlight photo)
- `inappropriate_content.jpg` (triggers SafeSearch reject - mocked response)
- `document.pdf` (invalid format)
- `huge_image.jpg` (10MB, exceeds size limit)

## Data Relationships

```
Service Type (1) -----> (N) Service Definition
     |
     |
     v
Service Request (N) -----> (1) Service Type
                    -----> (0..1) Service Definition
                    -----> (N) Test Images
                    -----> (0..1) Test User (if authenticated)

Test User (1) -----> (N) Service Request (authored by user)

Test Environment -----> Test Jurisdiction (geographic bounds)
```

## Data Seeding Workflow

1. **Suite Setup Phase**:
   - Verify Docker containers healthy (DockerLibrary)
   - Connect to database (DatabaseLibrary)
   - Clear test data from previous run (DELETE WHERE created_for_testing = true)
   - Seed service types (3-5 types)
   - Seed service definitions (2-3 per type)
   - Seed sample requests (20-30 total) for viewing tests
   - Seed test users for authenticated tests

2. **Individual Test Setup**:
   - Create test-specific data as needed (e.g., request for tracking test)
   - Set test markers for cleanup (created_for_testing flag)

3. **Individual Test Teardown**:
   - Clean up test-specific data created during test

4. **Suite Teardown Phase**:
   - Clean up all test data seeded during suite setup
   - Collect diagnostic logs if test failed
   - Verify database returned to clean state

## Validation Rules

### Data Quality Rules
- All email addresses must be valid format (regex validation)
- All phone numbers must be E.164 format (+1-XXX-XXX-XXXX)
- All coordinates must be within valid ranges (lat: -90 to 90, lng: -180 to 180)
- All timestamps must be ISO 8601 format with timezone
- All descriptions must be 10-1000 characters
- All addresses must include street, city, state, zip

### Open311 Compliance Rules
- Service codes must be alphanumeric, no spaces
- Request IDs must be unique and trackable
- Status values must be from allowed set (new, open, in_progress, resolved, closed)
- All required fields per Open311 spec must be present
- All API responses must conform to Open311 GeoReport v2 schema

### Test Isolation Rules
- Each test suite must use isolated database schema OR
- Each test suite must clean all data before/after execution
- No test may depend on data created by another test
- Parallel test execution must not cause data conflicts

## Data Generation Strategy

Use `TestDataGenerator.py` custom library leveraging robotframework-faker:

```python
# Example keyword usage in tests
${realistic_name}=    Generate Realistic Name
${realistic_email}=    Generate Email    domain=example.com
${realistic_phone}=    Generate US Phone Number
${realistic_address}=    Generate Minneapolis Address    within_boundaries=true
${realistic_description}=    Generate Service Request Description    service_code=POTHOLE    length=200
```

Benefits:
- Consistent realistic data across tests
- Locale-aware generation (US addresses, phone formats)
- Boundary-aware coordinate generation
- Descriptive text that sounds like real citizen reports
- Reduces test maintenance when data requirements change
