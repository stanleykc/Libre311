"""
TestDataGenerator - Custom Robot Framework library for generating realistic test data

This library leverages Faker to generate realistic test data for Libre311 acceptance tests,
including names, emails, phone numbers, addresses with valid coordinates, and descriptions.
"""

import random
from faker import Faker
from robot.api import logger


class TestDataGenerator:
    """Custom library for generating realistic test data"""

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = '1.0.0'

    def __init__(self, locale='en_US', seed=None):
        """
        Initialize Faker with specified locale

        Args:
            locale: Locale for generated data (default: en_US)
            seed: Random seed for reproducible data (default: None for random)
        """
        self.faker = Faker(locale)
        if seed is not None:
            Faker.seed(seed)
            random.seed(seed)

        # Minneapolis area boundaries (from data-model.md)
        self.MIN_LAT = 44.9000
        self.MAX_LAT = 45.0500
        self.MIN_LNG = -93.3290
        self.MAX_LNG = -93.1990

        # Service type templates for descriptions
        self.service_descriptions = {
            'POTHOLE': [
                "Large pothole approximately {size} feet wide and {depth} inches deep on {location}. Causing vehicles to swerve.",
                "Pothole on {location} near intersection with {street}. Approximately {size} feet in diameter.",
                "Deep pothole in {location} creating hazard for vehicles. Estimated size {size} feet wide.",
            ],
            'STREETLIGHT': [
                "Streetlight out for {days} days on {location}. Area very dark at night.",
                "Broken streetlight at {location} near {street}. Light not functioning.",
                "Streetlight pole damaged at {location}. Light fixture hanging loose.",
            ],
            'GRAFFITI': [
                "Graffiti spray painted on {location}. Approximately {size} feet wide.",
                "Vandalism on {location} building wall. Multiple tags visible.",
                "Graffiti on {location} facing {street}. Needs removal.",
            ],
        }

    def generate_realistic_name(self):
        """
        Generate realistic full name

        Returns:
            Full name string (first + last)
        """
        name = self.faker.name()
        logger.info(f"Generated name: {name}")
        return name

    def generate_first_name(self):
        """Generate realistic first name"""
        return self.faker.first_name()

    def generate_last_name(self):
        """Generate realistic last name"""
        return self.faker.last_name()

    def generate_email(self, domain='example.com'):
        """
        Generate realistic email address

        Args:
            domain: Email domain (default: example.com)

        Returns:
            Email address string
        """
        username = self.faker.user_name()
        email = f"{username}@{domain}"
        logger.info(f"Generated email: {email}")
        return email

    def generate_us_phone_number(self, area_code='612'):
        """
        Generate realistic US phone number in E.164 format

        Args:
            area_code: Area code (default: 612 for Minneapolis)

        Returns:
            Phone number string in +1-XXX-XXX-XXXX format
        """
        exchange = random.randint(200, 999)
        subscriber = random.randint(1000, 9999)
        phone = f"+1-{area_code}-{exchange:03d}-{subscriber:04d}"
        logger.info(f"Generated phone: {phone}")
        return phone

    def generate_minneapolis_address_with_coordinates(self):
        """
        Generate realistic Minneapolis address with valid coordinates within jurisdiction

        Returns:
            Tuple of (address_string, latitude, longitude)
        """
        # Generate random coordinates within Minneapolis bounds
        latitude = random.uniform(self.MIN_LAT, self.MAX_LAT)
        longitude = random.uniform(self.MIN_LNG, self.MAX_LNG)

        # Generate realistic street address
        street_number = random.randint(100, 9999)
        street_name = self.faker.street_name()
        street_suffix = random.choice(['St', 'Ave', 'Blvd', 'Rd', 'Ln', 'Dr'])
        zip_code = random.choice(['55401', '55402', '55403', '55404', '55405'])

        address = f"{street_number} {street_name} {street_suffix}, Minneapolis, MN {zip_code}"

        logger.info(f"Generated address: {address} ({latitude:.4f}, {longitude:.4f})")
        return address, latitude, longitude

    def generate_out_of_bounds_address(self):
        """
        Generate address outside Minneapolis jurisdiction boundaries

        Returns:
            Tuple of (address_string, latitude, longitude)
        """
        # Use St Paul coordinates (outside Minneapolis bounds)
        latitude = 44.9537
        longitude = -93.0900

        street_number = random.randint(100, 999)
        street_name = self.faker.street_name()
        address = f"{street_number} {street_name} St, St Paul, MN 55101"

        logger.info(f"Generated out-of-bounds address: {address}")
        return address, latitude, longitude

    def generate_service_request_description(self, service_code, length=None):
        """
        Generate realistic service request description

        Args:
            service_code: Service type code (POTHOLE, STREETLIGHT, GRAFFITI)
            length: Target length in characters (default: random 100-500)

        Returns:
            Description string
        """
        if length is None:
            length = random.randint(100, 500)

        # Get template for service type
        templates = self.service_descriptions.get(service_code, [
            "Issue reported at {location}. Requires attention."
        ])
        template = random.choice(templates)

        # Generate placeholder values
        placeholders = {
            'size': random.randint(1, 5),
            'depth': random.randint(2, 12),
            'days': random.randint(1, 7),
            'location': f"{self.faker.street_name()} {random.choice(['St', 'Ave', 'Blvd'])}",
            'street': f"{self.faker.street_name()} {random.choice(['St', 'Ave'])}",
        }

        # Fill template
        description = template.format(**placeholders)

        # Pad with additional detail if needed
        while len(description) < length:
            details = [
                " Reported by multiple residents.",
                " Creating safety hazard for pedestrians and vehicles.",
                " Urgent attention required.",
                " Has been an issue for several days.",
                " Please prioritize repair.",
            ]
            description += random.choice(details)

        # Trim to target length
        if len(description) > length:
            description = description[:length].rsplit(' ', 1)[0] + '.'

        logger.info(f"Generated description ({len(description)} chars): {description[:50]}...")
        return description

    def generate_test_user(self, user_id=None):
        """
        Generate realistic test user data for authenticated tests

        Args:
            user_id: Optional user ID (default: generated)

        Returns:
            Dict with user_id, email, name, oauth_token
        """
        if user_id is None:
            user_id = f"test-user-{random.randint(1000, 9999)}"

        first_name = self.generate_first_name()
        last_name = self.generate_last_name()
        name = f"{first_name} {last_name}"
        email = self.generate_email()
        oauth_token = f"mock-jwt-token-{self.faker.uuid4()[:8]}"

        user = {
            'user_id': user_id,
            'email': email,
            'name': name,
            'first_name': first_name,
            'last_name': last_name,
            'oauth_token': oauth_token,
        }

        logger.info(f"Generated test user: {name} ({email})")
        return user

    def generate_random_date_in_past(self, days_ago_min=1, days_ago_max=30):
        """
        Generate random date in the past

        Args:
            days_ago_min: Minimum days in past (default: 1)
            days_ago_max: Maximum days in past (default: 30)

        Returns:
            ISO 8601 datetime string
        """
        days_ago = random.randint(days_ago_min, days_ago_max)
        date = self.faker.date_time_between(start_date=f'-{days_ago}d', end_date='now')
        iso_date = date.isoformat() + 'Z'
        logger.info(f"Generated date: {iso_date}")
        return iso_date

    def generate_test_image_filename(self, service_code):
        """
        Generate appropriate test image filename for service type

        Args:
            service_code: Service type code

        Returns:
            Image filename string
        """
        image_map = {
            'POTHOLE': 'pothole_sample_1.jpg',
            'STREETLIGHT': 'streetlight_broken.jpg',
            'GRAFFITI': 'graffiti_sample.jpg',
        }
        filename = image_map.get(service_code, 'test_image.jpg')
        logger.info(f"Selected image: {filename}")
        return filename

    def set_seed(self, seed):
        """
        Set random seed for reproducible test data

        Args:
            seed: Integer seed value
        """
        Faker.seed(seed)
        random.seed(seed)
        logger.info(f"Set random seed: {seed}")
