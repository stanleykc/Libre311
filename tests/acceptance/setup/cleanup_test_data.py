#!/usr/bin/env python3
"""
Database cleanup script for Libre311 acceptance tests

This script removes all test data marked with created_for_testing=true flag.

Usage:
    python3 cleanup_test_data.py [--all]

Options:
    --all: Clean all data, not just test data (use with caution!)
"""

import sys
import argparse
import pymysql

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


def get_connection():
    """Create database connection"""
    return pymysql.connect(**DB_CONFIG)


def clean_test_data(conn):
    """Delete all test data marked with created_for_testing flag"""
    print("Cleaning test data marked with created_for_testing...")

    with conn.cursor() as cursor:
        # Clean in order of foreign key dependencies
        cursor.execute(f"DELETE FROM service_requests WHERE {TEST_DATA_MARKER}=1")
        requests_deleted = cursor.rowcount

        cursor.execute(f"DELETE FROM service_definitions WHERE {TEST_DATA_MARKER}=1")
        definitions_deleted = cursor.rowcount

        cursor.execute(f"DELETE FROM services WHERE {TEST_DATA_MARKER}=1")
        services_deleted = cursor.rowcount

    conn.commit()

    print(f"✓ Deleted {requests_deleted} service requests")
    print(f"✓ Deleted {definitions_deleted} service definitions")
    print(f"✓ Deleted {services_deleted} services")
    print("✓ Test data cleaned successfully")


def clean_all_data(conn):
    """Delete ALL data (use with caution!)"""
    print("⚠️  WARNING: Cleaning ALL data from database...")
    response = input("Are you sure? This will delete ALL data! Type 'yes' to confirm: ")

    if response.lower() != 'yes':
        print("✗ Cleanup cancelled")
        sys.exit(0)

    with conn.cursor() as cursor:
        # Clean in order of foreign key dependencies
        cursor.execute("DELETE FROM service_requests")
        requests_deleted = cursor.rowcount

        cursor.execute("DELETE FROM service_definitions")
        definitions_deleted = cursor.rowcount

        cursor.execute("DELETE FROM services")
        services_deleted = cursor.rowcount

    conn.commit()

    print(f"✓ Deleted {requests_deleted} service requests")
    print(f"✓ Deleted {definitions_deleted} service definitions")
    print(f"✓ Deleted {services_deleted} services")
    print("✓ All data cleaned")


def verify_cleanup(conn):
    """Verify test data has been removed"""
    with conn.cursor() as cursor:
        cursor.execute(f"SELECT COUNT(*) FROM service_requests WHERE {TEST_DATA_MARKER}=1")
        requests_count = cursor.fetchone()[0]

        cursor.execute(f"SELECT COUNT(*) FROM service_definitions WHERE {TEST_DATA_MARKER}=1")
        definitions_count = cursor.fetchone()[0]

        cursor.execute(f"SELECT COUNT(*) FROM services WHERE {TEST_DATA_MARKER}=1")
        services_count = cursor.fetchone()[0]

    if requests_count > 0 or definitions_count > 0 or services_count > 0:
        print(f"⚠️  Warning: {requests_count + definitions_count + services_count} test records still remain")
        return False
    else:
        print("✓ Verification: No test data remaining")
        return True


def main():
    """Main execution"""
    parser = argparse.ArgumentParser(description='Clean Libre311 test database')
    parser.add_argument('--all', action='store_true',
                        help='Clean ALL data (not just test data) - use with caution!')
    parser.add_argument('--verify', action='store_true',
                        help='Verify cleanup without making changes')
    args = parser.parse_args()

    try:
        print("Connecting to database...")
        conn = get_connection()
        print(f"✓ Connected to {DB_CONFIG['database']}")

        if args.verify:
            verify_cleanup(conn)
        elif args.all:
            clean_all_data(conn)
        else:
            clean_test_data(conn)
            verify_cleanup(conn)

        print("\n✓ Cleanup completed successfully!")

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
