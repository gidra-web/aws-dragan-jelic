import json
import logging
import os
import boto3  # type: ignore
import psycopg2
from psycopg2 import errors

# =================================================================================
# GLOBAL SETUP
# =================================================================================

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_manager = boto3.client('secretsmanager')
db_secret_arn = os.environ.get('DB_SECRET_ARN')
db_creds = None

ENABLE_CORS = True  # Toggle this if used with API Gateway

# =================================================================================
# HELPERS
# =================================================================================

def get_db_credentials():
    """Fetches DB credentials from Secrets Manager, caching them globally."""
    global db_creds
    if db_creds:
        return db_creds
    if not db_secret_arn:
        raise ValueError("DB_SECRET_ARN environment variable is not set.")
    try:
        logger.info("Fetching database credentials from Secrets Manager.")
        secret_response = secrets_manager.get_secret_value(SecretId=db_secret_arn)
        db_creds = json.loads(secret_response['SecretString'])
        return db_creds
    except Exception as e:
        logger.error(f"Failed to retrieve database credentials: {e}")
        raise

def get_db_connection():
    """Establishes a new PostgreSQL connection."""
    creds = get_db_credentials()
    return psycopg2.connect(
        host=creds['DB_HOST'],
        port=creds['DB_PORT'],
        dbname=creds['DB_NAME'],
        user=creds['DB_USER'],
        password=creds['DB_PASSWORD']
    )

def format_token_record(record):
    """Converts a token record tuple into a dictionary."""
    if not record:
        return None
    return {
        'id': record[0],
        'employee_id': record[1],
        'issued_at': record[2].isoformat()
    }

def response(status_code: int, body: dict | str):
    """Standard HTTP JSON response with optional CORS headers."""
    if isinstance(body, dict):
        body = json.dumps(body)

    headers = {"Content-Type": "application/json"}
    if ENABLE_CORS:
        headers.update({
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type"
        })

    return {
        'statusCode': status_code,
        'headers': headers,
        'body': body
    }

# =================================================================================
# CRUD HANDLERS
# =================================================================================

def handle_create_token(event):
    """Handles POST to create (issue) a new token for an employee."""
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employee_id')

        if not employee_id:
            return response(400, {'message': 'Missing required field: employee_id'})

        conn = get_db_connection()
        sql = "INSERT INTO tokens (employee_id) VALUES (%s) RETURNING id, issued_at;"

        with conn.cursor() as cur:
            cur.execute(sql, (employee_id,))
            new_token_id, issued_at = cur.fetchone()
            conn.commit()

        logger.info(f"Issued token {new_token_id} for employee {employee_id}")
        return response(201, {
            'token_id': new_token_id,
            'issued_at': issued_at.isoformat(),
            'message': 'Token issued successfully.'
        })

    except errors.ForeignKeyViolation:
        logger.warning(f"Employee not found for ID '{employee_id}'")
        return response(404, {'message': f"Employee with ID '{employee_id}' not found."})
    except Exception as e:
        logger.error(f"Error issuing token: {e}")
        return response(500, {'message': 'Error issuing token'})
    finally:
        if conn:
            conn.close()

def handle_read_token(event):
    """Handles GET to retrieve all tokens for a specific employee."""
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employee_id')

        if not employee_id:
            return response(400, {'message': 'Missing required field: employee_id'})

        conn = get_db_connection()
        sql = "SELECT id, employee_id, issued_at FROM tokens WHERE employee_id = %s ORDER BY issued_at DESC;"

        with conn.cursor() as cur:
            cur.execute(sql, (employee_id,))
            records = cur.fetchall()
            tokens = [format_token_record(rec) for rec in records]

        return response(200, tokens)

    except Exception as e:
        logger.error(f"Error retrieving tokens: {e}")
        return response(500, {'message': 'Error retrieving tokens'})
    finally:
        if conn:
            conn.close()

def handle_delete_token(event):
    """Handles DELETE to revoke a token by ID."""
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        token_id = body.get('id')

        if not token_id:
            return response(400, {'message': 'Missing required field: id'})

        conn = get_db_connection()
        sql = "DELETE FROM tokens WHERE id = %s;"

        with conn.cursor() as cur:
            cur.execute(sql, (token_id,))
            if cur.rowcount == 0:
                return response(404, {'message': 'Token not found'})
            conn.commit()

        logger.info(f"Revoked token with ID: {token_id}")
        return response(204, '')  # No content

    except Exception as e:
        logger.error(f"Error deleting token: {e}")
        return response(500, {'message': 'Error deleting token'})
    finally:
        if conn:
            conn.close()

# =================================================================================
# MAIN ENTRYPOINT
# =================================================================================

def lambda_handler(event, context):
    try:
        http_method = event['requestContext']['http']['method']
        path = event.get('rawPath', '')
        logger.info(f"Received {http_method} request for path {path}")

        if http_method == 'OPTIONS':
            return response(200, {})  # For CORS preflight

        if http_method == 'POST':
            return handle_create_token(event)
        elif http_method == 'GET':
            return handle_read_token(event)
        elif http_method == 'DELETE':
            return handle_delete_token(event)
        else:
            return response(405, {'message': f'Method {http_method} is not supported.'})

    except Exception as e:
        logger.error(f"Unhandled error in lambda_handler: {str(e)}")
        return response(500, {'message': 'Internal Server Error'})
