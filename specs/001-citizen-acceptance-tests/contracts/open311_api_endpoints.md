# Open311 GeoReport v2 API Contracts

**Purpose**: Define API endpoints that must be tested for Open311 compliance

**Specification**: [Open311 GeoReport v2](http://wiki.open311.org/GeoReport_v2/)

## Service Discovery

### GET /discovery
**Purpose**: Service discovery endpoint per Open311 specification

**Request**: No parameters

**Response**: 200 OK
```json
{
  "changeset": "2025-11-01",
  "contact": "Contact information for this installation",
  "endpoints": [
    {
      "specification": "http://wiki.open311.org/GeoReport_v2",
      "url": "http://libre311-api:8080/api",
      "changeset": "2025-11-01",
      "type": "production",
      "formats": ["application/json", "application/xml"]
    },
    {
      "specification": "http://wiki.open311.org/GeoReport_v2",
      "url": "http://libre311-api:8080/api",
      "changeset": "2025-11-01",
      "type": "test",
      "formats": ["application/json", "application/xml"]
    }
  ]
}
```

**Validation**:
- Response must be valid JSON
- Must include changeset, contact, endpoints array
- Each endpoint must have specification, url, type, formats

**Test Scenarios**:
- US1 (Browse Services): Verify discovery endpoint returns valid configuration
- Open311 compliance: Validate against GeoReport v2 schema

---

## Service List

### GET /services
**Purpose**: List all available service types citizens can report

**Request**: Optional query parameters
- `jurisdiction_id` (optional): Jurisdiction identifier

**Response**: 200 OK
```json
[
  {
    "service_code": "POTHOLE",
    "service_name": "Pothole",
    "description": "Report potholes or damaged road surfaces",
    "metadata": true,
    "type": "realtime",
    "keywords": ["road", "street", "asphalt", "pavement"],
    "group": "Streets & Roads"
  },
  {
    "service_code": "STREETLIGHT",
    "service_name": "Broken Streetlight",
    "description": "Report malfunctioning or dark streetlights",
    "metadata": true,
    "type": "realtime",
    "keywords": ["light", "lamp", "dark", "safety"],
    "group": "Public Safety"
  }
]
```

**Validation**:
- Response must be JSON array
- Each service must have service_code, service_name, description
- `metadata` true indicates service has definitions available
- `type` must be "realtime", "batch", or "blackbox"
- Open311 required fields: service_code, service_name, description, metadata, type

**Test Scenarios**:
- US1 (Browse Services): Verify all service types are returned
- US3 (Submit Request): Use service codes from this endpoint
- Open311 compliance: Validate field presence and format

---

## Service Definition

### GET /services/{service_code}
**Purpose**: Get detailed service definition including required/optional attributes

**Request**: Path parameter
- `service_code`: Service type code (e.g., "POTHOLE")

**Response**: 200 OK
```json
{
  "service_code": "POTHOLE",
  "attributes": [
    {
      "variable": true,
      "code": "POTHOLE_SIZE",
      "datatype": "singlevaluelist",
      "required": false,
      "datatype_description": "Estimated size of pothole",
      "order": 1,
      "description": "Approximate size of the pothole",
      "values": [
        {"key": "SMALL", "name": "Small (< 1 ft)"},
        {"key": "MEDIUM", "name": "Medium (1-2 ft)"},
        {"key": "LARGE", "name": "Large (> 2 ft)"}
      ]
    },
    {
      "variable": true,
      "code": "LOCATION_DETAIL",
      "datatype": "string",
      "required": false,
      "datatype_description": "Additional location information",
      "order": 2,
      "description": "Detailed description of exact location (e.g., 'near intersection with 1st Ave')",
      "values": []
    }
  ]
}
```

**Validation**:
- Response must contain service_code and attributes array
- Each attribute must have: variable, code, datatype, required
- `datatype` values: string, number, datetime, text, singlevaluelist, multivaluelist
- Open311 required fields per attribute: variable, code, datatype, required, order, description

**Test Scenarios**:
- US1 (Browse Services): Display service definition details to citizen
- US3 (Submit Request): Use required attributes for form validation
- Open311 compliance: Validate attribute structure

---

## Create Service Request

### POST /requests
**Purpose**: Submit a new service request

**Request**: application/json body
```json
{
  "service_code": "POTHOLE",
  "lat": 44.9778,
  "long": -93.2650,
  "address_string": "123 Main St, Minneapolis, MN 55401",
  "description": "Large pothole approximately 2 feet wide and 6 inches deep",
  "first_name": "Jennifer",
  "last_name": "Martinez",
  "email": "jennifer.martinez@example.com",
  "phone": "+1-612-555-0123",
  "media_url": "http://example.com/pothole_photo.jpg",
  "attribute[POTHOLE_SIZE]": "LARGE",
  "attribute[LOCATION_DETAIL]": "Near intersection with 1st Ave"
}
```

**Required Fields** (per Open311):
- `service_code`: Service type
- One of: `lat`+`long` OR `address_string` (location)
- `description`: Issue description

**Optional Fields**:
- `first_name`, `last_name`, `email`, `phone`: Contact info
- `media_url`: Link to uploaded image
- `attribute[CODE]`: Service-specific attributes

**Response**: 201 Created
```json
[
  {
    "service_request_id": "REQ-12345",
    "service_notice": "Request created successfully. You will receive updates at jennifer.martinez@example.com",
    "account_id": null
  }
]
```

**Validation**:
- Must return 201 status code
- Response must include service_request_id (tracking number)
- service_request_id must be unique and trackable
- Response must be JSON array (even for single request)

**Error Response**: 400 Bad Request
```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "description": "Required field 'description' is missing"
  }
}
```

**Test Scenarios**:
- US3 (Submit Anonymous Request): Create request with all fields
- US3 (Submit Anonymous Request): Create request with minimal fields (service_code, lat/long, description)
- US3 (Submit Anonymous Request): Verify image upload integration
- US5 (Submit Authenticated Request): Create request while logged in
- Edge case: Missing required fields returns 400
- Edge case: Invalid coordinates returns 400
- Open311 compliance: Validate request/response format

---

## Get Service Request

### GET /requests/{service_request_id}
**Purpose**: Retrieve details of a specific service request

**Request**: Path parameter
- `service_request_id`: Request tracking number

**Response**: 200 OK
```json
[
  {
    "service_request_id": "REQ-12345",
    "status": "open",
    "status_notes": "Work order created for street crew",
    "service_name": "Pothole",
    "service_code": "POTHOLE",
    "description": "Large pothole approximately 2 feet wide and 6 inches deep",
    "agency_responsible": "Public Works Department",
    "service_notice": "",
    "requested_datetime": "2025-11-01T08:30:00Z",
    "updated_datetime": "2025-11-01T09:15:00Z",
    "expected_datetime": "2025-11-03T17:00:00Z",
    "address": "123 Main St, Minneapolis, MN 55401",
    "lat": 44.9778,
    "long": -93.2650,
    "media_url": "http://storage.googleapis.com/libre311/images/pothole_123.jpg"
  }
]
```

**Validation**:
- Response must be JSON array (even for single request)
- Must include: service_request_id, status, service_code, description, requested_datetime
- Status must be: open, closed (Open311 minimum); Libre311 extends with: new, in_progress, resolved
- Timestamps must be ISO 8601 with timezone
- lat/long must be valid coordinates if present

**Error Response**: 404 Not Found
```json
{
  "error": {
    "code": "REQUEST_NOT_FOUND",
    "description": "No request found with ID REQ-99999"
  }
}
```

**Test Scenarios**:
- US2 (View Requests): Display individual request details
- US4 (Track Request): Look up request by tracking number
- Edge case: Invalid tracking number returns 404
- Open311 compliance: Validate response fields and format

---

## Get Multiple Service Requests

### GET /requests
**Purpose**: Query multiple service requests with filters

**Request**: Query parameters
- `service_request_id` (optional): Comma-separated list of request IDs
- `service_code` (optional): Filter by service type
- `start_date` (optional): Earliest requested_datetime (ISO 8601)
- `end_date` (optional): Latest requested_datetime (ISO 8601)
- `status` (optional): Filter by status (open, closed)

**Example**: `GET /requests?service_code=POTHOLE&status=open&start_date=2025-11-01T00:00:00Z`

**Response**: 200 OK
```json
[
  {
    "service_request_id": "REQ-12345",
    "status": "open",
    "service_name": "Pothole",
    "service_code": "POTHOLE",
    "description": "Large pothole...",
    "requested_datetime": "2025-11-01T08:30:00Z",
    "address": "123 Main St, Minneapolis, MN 55401",
    "lat": 44.9778,
    "long": -93.2650
  },
  {
    "service_request_id": "REQ-12346",
    "status": "open",
    "service_name": "Pothole",
    "service_code": "POTHOLE",
    "description": "Pothole on bike lane...",
    "requested_datetime": "2025-11-01T14:22:00Z",
    "address": "456 Oak Ave, Minneapolis, MN 55403",
    "lat": 44.9830,
    "long": -93.2689
  }
]
```

**Validation**:
- Response must be JSON array (empty array if no results)
- Filters must be applied correctly (verify test data matches filters)
- Results must be ordered by requested_datetime DESC (most recent first)
- Maximum results per request: 100 (pagination if more)

**Test Scenarios**:
- US2 (View Requests): Query requests by service type
- US2 (View Requests): Query requests by status
- US2 (View Requests): Query requests by date range
- US4 (Track by Email): Query requests by email (if supported)
- Edge case: No results returns empty array []
- Open311 compliance: Validate filter parameters and response format

---

## Non-Open311 Endpoints (Libre311 Extensions)

These endpoints are Libre311-specific and not part of Open311 spec.

### GET /requests (with pagination)
**Libre311 Extension**: Pagination support

**Additional Query Parameters**:
- `page` (optional): Page number (default: 1)
- `limit` (optional): Results per page (default: 50, max: 100)

### POST /requests/{service_request_id}/images
**Libre311 Extension**: Image upload after request creation

**Request**: multipart/form-data
- `image`: Image file (JPEG, PNG)

**Response**: 201 Created
```json
{
  "image_url": "http://storage.googleapis.com/libre311/images/pothole_123.jpg",
  "safesearch_status": "approved"
}
```

**Error Response**: 400 Bad Request
```json
{
  "error": {
    "code": "INAPPROPRIATE_CONTENT",
    "description": "Image contains inappropriate content and cannot be accepted"
  }
}
```

### GET /users/me/requests
**Libre311 Extension**: Get all requests for authenticated user

**Authentication**: Requires JWT token (Google OAuth)

**Response**: 200 OK
```json
[
  {
    "service_request_id": "REQ-12345",
    "status": "open",
    "service_name": "Pothole",
    "requested_datetime": "2025-11-01T08:30:00Z"
  }
]
```

---

## RESTinstance Test Strategy

### Schema Validation
Use RESTinstance to validate API responses against JSON schema:

```robot
*** Test Cases ***
Verify GET /services Returns Valid Open311 Schema
    GET    ${API_BASE_URL}/services
    Integer    response status    200
    Array    response body
    Object    response body 0
    String    response body 0 service_code
    String    response body 0 service_name
    String    response body 0 description
    Boolean    response body 0 metadata
    String    response body 0 type    enum=["realtime", "batch", "blackbox"]
```

### Open311Validator.py Custom Library
Create Python library for Open311-specific validation:

```python
class Open311Validator:
    def validate_service_list_response(self, response_json):
        """Validates GET /services response against Open311 GeoReport v2 spec"""
        # Check required fields, data types, constraints
        pass

    def validate_service_request_response(self, response_json):
        """Validates POST /requests response format"""
        pass

    def validate_service_request_id_format(self, request_id):
        """Validates request ID format and uniqueness"""
        pass
```

### Test Coverage Matrix

| Endpoint | User Story | Priority | Open311 Compliance | Test Count |
|----------|-----------|----------|-------------------|------------|
| GET /discovery | US1 | P1 | Yes | 2 |
| GET /services | US1, US3 | P1 | Yes | 4 |
| GET /services/{code} | US1, US3 | P1 | Yes | 3 |
| GET /requests | US2 | P1 | Yes | 6 |
| GET /requests/{id} | US2, US4 | P1 | Yes | 4 |
| POST /requests | US3, US5 | P2 | Yes | 8 |

**Total API Test Cases**: ~27 (not including edge cases)

---

## Performance Requirements

Per success criteria SC-008:
- 95% of API calls must complete within 10 seconds
- GET operations typically < 1 second
- POST operations typically < 3 seconds
- Open311 spec does not define performance requirements, so these are Libre311-specific

## Security Requirements

- **Authentication**: OAuth token required for GET /users/me/requests
- **Rate Limiting**: Not specified in Open311, may exist in Libre311
- **Input Validation**: All endpoints must validate input and return 400 for invalid data
- **SQL Injection**: Must be tested via malicious input strings
- **XSS Prevention**: HTML/script tags in description fields must be escaped

## Mock Strategy for External Services

Since tests mock external services per constitution principle I:

1. **UnityAuth**: Mock authentication responses (JWT validation)
2. **Google OAuth**: Mock OAuth flow (handled by Browser Library network interception)
3. **Google Cloud Storage**: Mock image upload responses (201 Created with mock URL)
4. **SafeSearch API**: Mock content moderation responses (safe/unsafe)
5. **ReCaptcha**: Mock validation responses (test tokens always valid)

All mocks configured in `resources/variables/environments.robot`
