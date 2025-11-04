"""
Open311Validator - Custom Robot Framework library for Open311 GeoReport v2 compliance validation

This library provides keywords for validating Libre311 API responses against the Open311
GeoReport v2 specification: http://wiki.open311.org/GeoReport_v2/
"""

import re
from datetime import datetime
from robot.api import logger


class Open311Validator:
    """Custom library for Open311 GeoReport v2 API compliance validation"""

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = '1.0.0'

    # Open311 required fields per endpoint
    SERVICE_REQUIRED_FIELDS = ['service_code', 'service_name', 'description', 'metadata', 'type']
    SERVICE_DEFINITION_REQUIRED_FIELDS = ['service_code', 'attributes']
    SERVICE_REQUEST_REQUIRED_FIELDS = ['service_request_id', 'status', 'service_code',
                                       'description', 'requested_datetime']

    # Valid Open311 values
    VALID_SERVICE_TYPES = ['realtime', 'batch', 'blackbox']
    VALID_REQUEST_STATUSES = ['open', 'closed']  # Libre311 extends with: new, in_progress, resolved
    VALID_ATTRIBUTE_DATATYPES = ['string', 'number', 'datetime', 'text', 'singlevaluelist', 'multivaluelist']

    def validate_service_list_response(self, response_body):
        """
        Validate GET /services response against Open311 GeoReport v2 spec

        Args:
            response_body: Response body (should be list of service dicts)

        Returns:
            True if valid, raises AssertionError if invalid
        """
        # Response must be a list
        if not isinstance(response_body, list):
            raise AssertionError(f"Service list response must be array, got {type(response_body).__name__}")

        if len(response_body) == 0:
            logger.warn("Service list response is empty")
            return True

        # Validate each service
        for i, service in enumerate(response_body):
            try:
                self._validate_service_fields(service)
            except AssertionError as e:
                raise AssertionError(f"Service at index {i} invalid: {str(e)}")

        logger.info(f"Validated {len(response_body)} services against Open311 spec")
        return True

    def validate_service_definition_response(self, response_body):
        """
        Validate GET /services/{service_code} response

        Args:
            response_body: Response body (should be dict with service_code and attributes)

        Returns:
            True if valid, raises AssertionError if invalid
        """
        if not isinstance(response_body, dict):
            raise AssertionError(f"Service definition must be object, got {type(response_body).__name__}")

        # Check required fields
        for field in self.SERVICE_DEFINITION_REQUIRED_FIELDS:
            if field not in response_body:
                raise AssertionError(f"Missing required field: {field}")

        # Validate attributes structure
        attributes = response_body.get('attributes', [])
        if not isinstance(attributes, list):
            raise AssertionError(f"attributes must be array, got {type(attributes).__name__}")

        # Validate each attribute
        for i, attr in enumerate(attributes):
            try:
                self._validate_attribute_fields(attr)
            except AssertionError as e:
                raise AssertionError(f"Attribute at index {i} invalid: {str(e)}")

        logger.info(f"Validated service definition with {len(attributes)} attributes")
        return True

    def validate_service_request_response(self, response_body):
        """
        Validate POST /requests or GET /requests/{id} response

        Args:
            response_body: Response body (should be list with single request dict)

        Returns:
            True if valid, raises AssertionError if invalid
        """
        # Response must be array (even for single request)
        if not isinstance(response_body, list):
            raise AssertionError(f"Service request response must be array, got {type(response_body).__name__}")

        if len(response_body) == 0:
            raise AssertionError("Service request response array is empty")

        # Validate request
        request = response_body[0]
        self._validate_request_fields(request)

        logger.info(f"Validated service request: {request.get('service_request_id')}")
        return True

    def validate_request_id_format(self, request_id):
        """
        Validate service request ID format

        Args:
            request_id: Request ID string

        Returns:
            True if valid format, raises AssertionError if invalid
        """
        if not isinstance(request_id, str):
            raise AssertionError(f"Request ID must be string, got {type(request_id).__name__}")

        if not request_id or len(request_id) == 0:
            raise AssertionError("Request ID cannot be empty")

        # Libre311 format: typically numeric or alphanumeric
        # Allow alphanumeric, hyphens, underscores
        if not re.match(r'^[A-Za-z0-9\-_]+$', request_id):
            raise AssertionError(f"Invalid request ID format: {request_id}")

        logger.info(f"Validated request ID format: {request_id}")
        return True

    def validate_open311_required_fields(self, data, required_fields):
        """
        Generic validator for checking required fields exist

        Args:
            data: Dict to validate
            required_fields: List of required field names

        Returns:
            True if all fields present, raises AssertionError if missing
        """
        if not isinstance(data, dict):
            raise AssertionError(f"Data must be dict, got {type(data).__name__}")

        missing = []
        for field in required_fields:
            if field not in data:
                missing.append(field)

        if missing:
            raise AssertionError(f"Missing required fields: {', '.join(missing)}")

        logger.info(f"All required fields present: {', '.join(required_fields)}")
        return True

    def validate_iso8601_datetime(self, datetime_string):
        """
        Validate datetime string is ISO 8601 format

        Args:
            datetime_string: Datetime string to validate

        Returns:
            True if valid, raises AssertionError if invalid
        """
        try:
            # Try parsing ISO 8601 format
            datetime.fromisoformat(datetime_string.replace('Z', '+00:00'))
            logger.info(f"Valid ISO 8601 datetime: {datetime_string}")
            return True
        except (ValueError, AttributeError) as e:
            raise AssertionError(f"Invalid ISO 8601 datetime: {datetime_string} - {str(e)}")

    def validate_coordinates(self, latitude, longitude):
        """
        Validate geographic coordinates are in valid ranges

        Args:
            latitude: Latitude value
            longitude: Longitude value

        Returns:
            True if valid, raises AssertionError if invalid
        """
        try:
            lat = float(latitude)
            lng = float(longitude)
        except (ValueError, TypeError) as e:
            raise AssertionError(f"Coordinates must be numeric: {str(e)}")

        if not (-90 <= lat <= 90):
            raise AssertionError(f"Latitude must be between -90 and 90, got {lat}")

        if not (-180 <= lng <= 180):
            raise AssertionError(f"Longitude must be between -180 and 180, got {lng}")

        logger.info(f"Valid coordinates: {lat}, {lng}")
        return True

    # Private helper methods

    def _validate_service_fields(self, service):
        """Validate individual service has all required Open311 fields"""
        for field in self.SERVICE_REQUIRED_FIELDS:
            if field not in service:
                raise AssertionError(f"Missing required field: {field}")

        # Validate 'type' is valid value
        service_type = service.get('type')
        if service_type not in self.VALID_SERVICE_TYPES:
            raise AssertionError(f"Invalid service type: {service_type}, must be one of {self.VALID_SERVICE_TYPES}")

        # Validate 'metadata' is boolean
        metadata = service.get('metadata')
        if not isinstance(metadata, bool):
            raise AssertionError(f"metadata must be boolean, got {type(metadata).__name__}")

        return True

    def _validate_attribute_fields(self, attribute):
        """Validate service definition attribute structure"""
        required = ['variable', 'code', 'datatype', 'required', 'order', 'description']
        for field in required:
            if field not in attribute:
                raise AssertionError(f"Attribute missing required field: {field}")

        # Validate datatype
        datatype = attribute.get('datatype')
        if datatype not in self.VALID_ATTRIBUTE_DATATYPES:
            raise AssertionError(f"Invalid attribute datatype: {datatype}")

        # Validate 'required' is boolean
        if not isinstance(attribute.get('required'), bool):
            raise AssertionError("Attribute 'required' must be boolean")

        return True

    def _validate_request_fields(self, request):
        """Validate service request has all required Open311 fields"""
        for field in self.SERVICE_REQUEST_REQUIRED_FIELDS:
            if field not in request:
                raise AssertionError(f"Missing required field: {field}")

        # Validate request ID format
        self.validate_request_id_format(request.get('service_request_id'))

        # Validate status (Libre311 extends Open311 statuses)
        status = request.get('status')
        extended_statuses = self.VALID_REQUEST_STATUSES + ['new', 'in_progress', 'resolved']
        if status not in extended_statuses:
            raise AssertionError(f"Invalid status: {status}")

        # Validate datetime if present
        if 'requested_datetime' in request:
            self.validate_iso8601_datetime(request['requested_datetime'])

        # Validate coordinates if present
        if 'lat' in request and 'long' in request:
            self.validate_coordinates(request['lat'], request['long'])

        return True
