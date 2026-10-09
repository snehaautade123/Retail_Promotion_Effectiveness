# ==========================================
# RETAIL PROMOTION EFFECTIVENESS
# PYTHON ETL PIPELINE
# ==========================================

from pathlib import Path


# ------------------------------------------
# 1. PROJECT PATHS
# ------------------------------------------

# This file is inside Python_ETL.
# parent = Python_ETL
# parent.parent = main project folder
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Folder containing the raw CSV files
DATA_DIR = PROJECT_ROOT / "Data"


# ------------------------------------------
# 2. SOURCE FILES
# ------------------------------------------

TRANSACTION_FILE = DATA_DIR / "transaction_data.csv"
PRODUCT_FILE = DATA_DIR / "product.csv"
CAUSAL_FILE = DATA_DIR / "causal_data.csv"


# ------------------------------------------
# 3. BASIC FILE CHECK
# ------------------------------------------

def check_input_files():
    """Check that all required CSV files are available."""

    required_files = [
        TRANSACTION_FILE,
        PRODUCT_FILE,
        CAUSAL_FILE,
    ]

    for file_path in required_files:
        if not file_path.exists():
            raise FileNotFoundError(
                f"Required file not found: {file_path}"
            )

    print("All required input files are available.")


# ==========================================
# 4. POSTGRESQL CONNECTION
# ==========================================

import os
import psycopg2
from dotenv import load_dotenv


# Load database settings from the .env file
load_dotenv()


def get_database_connection():
    """Create a connection to the PostgreSQL database."""

    try:
        connection = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT"),
            database=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
        )

        print("PostgreSQL connection successful.")
        return connection

    except Exception as error:
        print(f"PostgreSQL connection failed: {error}")
        return None

# ==========================================
# 5. LOAD CSV DATA INTO POSTGRESQL
# ==========================================

def load_csv_to_postgres(connection, csv_file, table_name, columns):
    """
    Load a CSV file directly into a PostgreSQL table.

    The file is streamed into PostgreSQL instead of
    loading the entire file into memory.
    """

    copy_query = f"""
    COPY {table_name} ({columns})
    FROM STDIN
    WITH (
        FORMAT csv,
        HEADER true,
        NULL ''
    )
    """

    try:
        with connection.cursor() as cursor:
            with open(csv_file, "r", encoding="utf-8") as file:
                cursor.copy_expert(copy_query, file)

        connection.commit()
        print(f"Loaded: {csv_file.name}")

    except Exception as error:
        connection.rollback()
        print(f"Failed to load {csv_file.name}: {error}")
        raise

# ==========================================
# 6. CSV TO POSTGRESQL LOAD SETTINGS
# ==========================================

# These are the core tables used in our analysis.
# We are not loading unused source tables into the pipeline.

LOAD_CONFIG = [
    {
        "file": TRANSACTION_FILE,
        "table": "retail.transactions",
        "columns": """
            household_key,
            basket_id,
            day,
            product_id,
            quantity,
            sales_value,
            store_id,
            retail_disc,
            trans_time,
            week_no,
            coupon_disc,
            coupon_match_disc
        """,
    },
    {
        "file": PRODUCT_FILE,
        "table": "retail.products",
        "columns": """
            product_id,
            manufacturer,
            department,
            brand,
            commodity_desc,
            sub_commodity_desc,
            curr_size_of_product
        """,
    },
    {
        "file": CAUSAL_FILE,
        "table": "retail.causal_raw",
        "columns": """
            product_id,
            store_id,
            week_no,
            display,
            mailer
        """,
    },
]

# ==========================================
# 7. ETL VALIDATION + LOAD
# ==========================================

import argparse


def validate_load_config():
    """
    Check the ETL loading plan without changing the database.
    """

    print("\nETL load plan:")

    for item in LOAD_CONFIG:
        file_path = item["file"]

        print(f"- File: {file_path.name}")
        print(f"  Target table: {item['table']}")
        print(
            f"  File size: "
            f"{file_path.stat().st_size / (1024 * 1024):.2f} MB"
        )

    print("\nDry run completed. No data was loaded.")


def validate_target_tables(connection):
    """Check that all target PostgreSQL tables exist."""

    required_tables = [
        "retail.transactions",
        "retail.products",
        "retail.causal_raw",
    ]

    with connection.cursor() as cursor:

        for table_name in required_tables:

            cursor.execute(
                "SELECT to_regclass(%s);",
                (table_name,)
            )

            result = cursor.fetchone()[0]

            if result is None:
                raise RuntimeError(
                    f"Target table does not exist: {table_name}"
                )

    print("All target PostgreSQL tables exist.")


def get_table_row_count(connection, table_name):
    """Return row count for a PostgreSQL table."""

    with connection.cursor() as cursor:
        cursor.execute(
            f"SELECT COUNT(*) FROM {table_name};"
        )

        return cursor.fetchone()[0]


def truncate_target_tables(connection):
    """
    Clear existing ETL target data before a full refresh.

    Only the three raw ETL target tables are affected.
    Source CSV files are not modified.
    """

    truncate_query = """
        TRUNCATE TABLE
            retail.transactions,
            retail.products,
            retail.causal_raw;
    """

    with connection.cursor() as cursor:
        cursor.execute(truncate_query)

    connection.commit()

    print("Existing ETL target data cleared.")


def run_full_load(connection):
    """Load all configured CSV files into PostgreSQL."""

    validate_target_tables(connection)

    print("\nStarting full ETL load...")

    truncate_target_tables(connection)

    for item in LOAD_CONFIG:

        file_path = item["file"]
        table_name = item["table"]
        columns = item["columns"]

        print(f"\nLoading {file_path.name}...")
        print(f"Target: {table_name}")

        load_csv_to_postgres(
            connection=connection,
            csv_file=file_path,
            table_name=table_name,
            columns=columns,
        )

        row_count = get_table_row_count(
            connection,
            table_name
        )

        print(
            f"PostgreSQL rows in {table_name}: "
            f"{row_count:,}"
        )

    print("\nFull ETL load completed successfully.")


# ==========================================
# 8. COMMAND LINE ENTRY POINT
# ==========================================

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Retail Promotion Effectiveness ETL pipeline"
    )

    parser.add_argument(
        "--load",
        action="store_true",
        help="Load CSV data into PostgreSQL"
    )

    args = parser.parse_args()

    check_input_files()

    if not args.load:

        validate_load_config()

    else:

        connection = get_database_connection()

        if connection is None:
            raise RuntimeError(
                "ETL stopped because PostgreSQL connection failed."
            )

        try:
            run_full_load(connection)

        finally:
            connection.close()
            print("\nPostgreSQL connection closed.")