#!/usr/bin/env python3
"""
Database seeding script for Libre311 acceptance tests

This script seeds the test database with service types, service definitions,
and sample service requests for acceptance testing.

Usage:
    python3 seed_test_data.py [--clean] [--count N]

Options:
    --clean: Clean existing test data before seeding
    --count N: Number of sample requests to create (default: 20)
"""

import sys
import argparse
import pymysql
from datetime import datetime, timedelta
import random

# Database configuration (matches environments.robot)
DB_CONFIG = {
    'host': 'localhost',
    'port': 23306,
    'user': 'libre311user',
    'password': 'libre311pass',
    'database': 'libre311db',
    'charset': 'utf8mb4',
}

# Test data marker
TEST_DATA_MARKER = 'created_for_testing'

# Service types (from data-model.md)
SERVICE_TYPES = [
    {
        'service_code': 'POTHOLE',
        'service_name': 'Pothole',
        'description': 'Report potholes or damaged road surfaces',
        'category': 'Streets & Roads',
        'keywords': 'road,street,asphalt,pavement',
    },
    {
        'service_code': 'STREETLIGHT',
        'service_name': 'Broken Streetlight',
        'description': 'Report malfunctioning or dark streetlights',
        'category': 'Public Safety',
        'keywords': 'light,lamp,dark,safety',
    },
    {
        'service_code': 'GRAFFITI',
        'service_name': 'Graffiti Removal',
        'description': 'Report graffiti on public property',
        'category': 'Vandalism',
        'keywords': 'vandalism,tagging,spray paint',
    },
]

# Service definitions
SERVICE_DEFINITIONS = [
    {
        'definition_code': 'POTHOLE_ROAD',
        'service_code': 'POTHOLE',
        'definition_name': 'Pothole - Road',
        'required_fields': 'location,description,size_estimate',
        'expected_response_time': '48 hours',
    },
    {
        'definition_code': 'POTHOLE_SIDEWALK',
        'service_code': 'POTHOLE',
        'definition_name': 'Pothole - Sidewalk',
        'required_fields': 'location,description',
        'expected_response_time': '72 hours',
    },
]

# Sample addresses (Minneapolis area)
SAMPLE_ADDRESSES = [
    {'address': '123 Main St, Minneapolis, MN 55401', 'lat': 44.9778, 'lng': -93.2650},
    {'address': '456 Oak Ave, Minneapolis, MN 55403', 'lat': 44.9830, 'lng': -93.2689},
    {'address': '789 Elm Blvd, Minneapolis, MN 55404', 'lat': 44.9750, 'lng': -93.2700},
    {'address': '234 Pine St, Minneapolis, MN 55401', 'lat': 44.9800, 'lng': -93.2620},
    {'address': '567 Maple Dr, Minneapolis, MN 55403', 'lat': 44.9850, 'lng': -93.2710},
]

# Sample statuses
STATUSES = ['new', 'open', 'in_progress', 'resolved', 'closed']


def get_connection():
    """Create database connection"""
    return pymysql.connect(**DB_CONFIG)


def clean_test_data(conn):
    """Delete all test data marked with created_for_testing flag"""
    print("Cleaning existing test data...")
    with conn.cursor() as cursor:
        cursor.execute(f"DELETE FROM service_requests WHERE {TEST_DATA_MARKER}=1")
        cursor.execute(f"DELETE FROM service_definitions WHERE {TEST_DATA_MARKER}=1")
        cursor.execute(f"DELETE FROM services WHERE {TEST_DATA_MARKER}=1")
    conn.commit()
    print("✓ Test data cleaned")


def seed_service_types(conn):
    """Insert service types"""
    print("Seeding service types...")
    with conn.cursor() as cursor:
        for service in SERVICE_TYPES:
            sql = f"""
                INSERT INTO services
                (service_code, service_name, description, category, keywords, {TEST_DATA_MARKER})
                VALUES (%(service_code)s, %(service_name)s, %(description)s,
                        %(category)s, %(keywords)s, 1)
                ON DUPLICATE KEY UPDATE
                    service_name=VALUES(service_name),
                    description=VALUES(description)
            """
            cursor.execute(sql, service)
    conn.commit()
    print(f"✓ Seeded {len(SERVICE_TYPES)} service types")


def seed_service_definitions(conn):
    """Insert service definitions"""
    print("Seeding service definitions...")
    with conn.cursor() as cursor:
        for definition in SERVICE_DEFINITIONS:
            sql = f"""
                INSERT INTO service_definitions
                (definition_code, service_code, definition_name, required_fields,
                 expected_response_time, {TEST_DATA_MARKER})
                VALUES (%(definition_code)s, %(service_code)s, %(definition_name)s,
                        %(required_fields)s, %(expected_response_time)s, 1)
                ON DUPLICATE KEY UPDATE
                    definition_name=VALUES(definition_name)
            """
            cursor.execute(sql, definition)
    conn.commit()
    print(f"✓ Seeded {len(SERVICE_DEFINITIONS)} service definitions")


def seed_sample_requests(conn, count=20):
    """Insert sample service requests"""
    print(f"Seeding {count} sample service requests...")

    descriptions = {
        'POTHOLE': [
            "Large pothole approximately 2 feet wide causing vehicles to swerve",
            "Deep pothole in road creating hazard for vehicles",
            "Pothole near intersection needs urgent repair",
        ],
        'STREETLIGHT': [
            "Streetlight has been out for several days",
            "Broken streetlight creating dark area at night",
            "Streetlight pole damaged and light not functioning",
        ],
        'GRAFFITI': [
            "Graffiti spray painted on building wall",
            "Multiple graffiti tags visible on public property",
            "Vandalism on building needs removal",
        ],
    }

    with conn.cursor() as cursor:
        for i in range(count):
            service_code = random.choice([s['service_code'] for s in SERVICE_TYPES])
            location = random.choice(SAMPLE_ADDRESSES)
            status = random.choice(STATUSES)
            days_ago = random.randint(1, 30)
            submitted_date = datetime.now() - timedelta(days=days_ago)

            # Generate description
            desc_options = descriptions.get(service_code, ["Issue reported requiring attention"])
            description = random.choice(desc_options)

            sql = f"""
                INSERT INTO service_requests
                (service_code, latitude, longitude, address, description,
                 contact_name, contact_email, contact_phone, status, submitted_date, {TEST_DATA_MARKER})
                VALUES (%(service_code)s, %(lat)s, %(lng)s, %(address)s, %(description)s,
                        %(name)s, %(email)s, %(phone)s, %(status)s, %(submitted_date)s, 1)
            """

            data = {
                'service_code': service_code,
                'lat': location['lat'],
                'lng': location['lng'],
                'address': location['address'],
                'description': description,
                'name': f"Test User {i+1}",
                'email': f"testuser{i+1}@example.com",
                'phone': f"+1-612-555-{1000+i:04d}",
                'status': status,
                'submitted_date': submitted_date,
            }

            cursor.execute(sql, data)

    conn.commit()
    print(f"✓ Seeded {count} sample service requests")


def main():
    """Main execution"""
    parser = argparse.ArgumentParser(description='Seed Libre311 test database')
    parser.add_argument('--clean', action='store_true', help='Clean existing test data first')
    parser.add_argument('--count', type=int, default=20, help='Number of sample requests (default: 20)')
    args = parser.parse_args()

    try:
        print("Connecting to database...")
        conn = get_connection()
        print(f"✓ Connected to {DB_CONFIG['database']}")

        if args.clean:
            clean_test_data(conn)

        seed_service_types(conn)
        seed_service_definitions(conn)
        seed_sample_requests(conn, args.count)

        print("\n✓ Database seeding completed successfully!")

    except pymysql.Error as e:
        print(f"\n✗ Database error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if 'conn' in locals():
            conn.close()


if __name__ == '__main__':
    main()
