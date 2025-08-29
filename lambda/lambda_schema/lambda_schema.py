import os
import psycopg2
import boto3
import json

secrets_manager = boto3.client('secretsmanager')
db_secret_arn = os.environ.get('DB_SECRET_ARN')
db_creds = None 

def get_db_credentials():
    global db_creds
    if db_creds:
        return db_creds
    if not db_secret_arn:
        raise ValueError("DB_SECRET_ARN environment variable is not set.")
    try:
        print("Fetching database credentials from Secrets Manager.")
        secret_response = secrets_manager.get_secret_value(SecretId=db_secret_arn)
        db_creds = json.loads(secret_response['SecretString'])
        return db_creds
    except Exception as e:
        print(f"Failed to retrieve database credentials: {e}")
        raise

def get_db_connection():
    creds = get_db_credentials()
    return psycopg2.connect(
        host=creds['DB_HOST'],
        port=creds['DB_PORT'],
        dbname=creds['DB_NAME'],
        user=creds['DB_USER'],
        password=creds['DB_PASSWORD']
    )

def lambda_handler(event, context):
    conn = None
    try:
        print("Attempting to connect to the database...")
        conn = get_db_connection()
        print("Database connection successful.")
        
        cursor = conn.cursor()
        
        print("Executing schema setup SQL...")
        cursor.execute("""
            CREATE EXTENSION IF NOT EXISTS pgcrypto;

            CREATE TABLE IF NOT EXISTS employees ( 
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );

            CREATE TABLE IF NOT EXISTS tokens ( 
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
                issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            );

            CREATE INDEX IF NOT EXISTS idx_employees_email ON employees (email);
            CREATE INDEX IF NOT EXISTS idx_tokens_employee_id ON tokens (employee_id);
        """)
        
        conn.commit()
        print("Schema successfully applied.")
        
        return {
            'statusCode': 200,
            'body': 'Database initialized successfully.'
        }
    except Exception as e:
        print(f"Error initializing database: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error initializing database: {str(e)}'
        }
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if conn:
            conn.close()
            print("Database connection closed.")
