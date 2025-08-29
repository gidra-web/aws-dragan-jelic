
import json
import logging
import os
import boto3 #type: ignore
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

# =================================================================================
# HELPER FUNCTIONS
# =================================================================================

def _response(status, body):
    return {
        'statusCode': status,
        'headers': {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "https://dragan.stilltesting.xyz",  # Or "*", but best to use your frontend origin
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
            "Access-Control-Allow-Methods": "OPTIONS,GET,POST,PUT,DELETE"
        },
        'body': json.dumps(body)
    }

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
    """Establishes a new database connection."""
    creds = get_db_credentials()
    return psycopg2.connect(
        host=creds['DB_HOST'],
        port=creds['DB_PORT'],
        dbname=creds['DB_NAME'],
        user=creds['DB_USER'],
        password=creds['DB_PASSWORD']
    )

def format_employee_record(record):
    """Converts a database record tuple into a dictionary."""
    if not record:
        return None
    #
    return {
        'id': record[0],
        'first_name': record[1],
        'last_name': record[2],
        'email': record[3],
        'created_at': record[4].isoformat() # Format timestamp as string
    }

# =================================================================================
# CRUD HANDLERS
# =================================================================================
def handle_create_employee(event):
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        first_name, last_name, email = body.get('first_name'), body.get('last_name'), body.get('email')

        if not all([first_name, last_name, email]):
            return {'statusCode': 400, 'body': json.dumps({'message': 'Missing required fields: first_name, last_name, email'})}

        conn = get_db_connection()
        sql = "INSERT INTO employees (first_name, last_name, email) VALUES (%s, %s, %s) RETURNING id;"
        
        with conn.cursor() as cur:
            cur.execute(sql, (first_name, last_name, email))
            new_employee_id = cur.fetchone()[0]
            conn.commit()
        
        logger.info(f"Successfully created employee with ID: {new_employee_id}")
        return {'statusCode': 201, 'body': json.dumps({'employee_id': new_employee_id, 'message': 'Employee created successfully.'})}
    except (psycopg2.errors.UniqueViolation):
        logger.error(f"Conflict: The email '{email}' already exists.")
        return {'statusCode': 409, 'body': json.dumps({'message': f"An employee with the email '{email}' already exists."})}
    finally:
        if conn: conn.close()

def handle_read_employee(event):
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employee_id')
        conn = get_db_connection()

        with conn.cursor() as cur:
            if employee_id:
                # Get ONE employee by ID from body
                logger.info(f"Fetching employee with ID from body: {employee_id}")
                sql = "SELECT id, first_name, last_name, email, created_at FROM employees WHERE id = %s;"
                cur.execute(sql, (employee_id,))
                record = cur.fetchone()
                if not record:
                    return {'statusCode': 404, 'body': json.dumps({'message': 'Employee not found.'})}
                return {'statusCode': 200, 'body': json.dumps(format_employee_record(record))}
            else:
                # Get ALL employees
                logger.info("Fetching all employees.")
                sql = "SELECT id, first_name, last_name, email, created_at FROM employees ORDER BY created_at DESC;"
                cur.execute(sql)
                records = cur.fetchall()
                employees = [format_employee_record(rec) for rec in records]
                return {'statusCode': 200, 'body': json.dumps(employees)}
    finally:
        if conn: conn.close()

def handle_update_employee(event):
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employee_id')
        if not employee_id:
            return {'statusCode': 400, 'body': json.dumps({'message': 'employee_id is missing from request body.'})}
        
        update_fields, update_values = [], []
        for key, value in body.items():
            if key in ['first_name', 'last_name', 'email']:
                update_fields.append(f"{key} = %s")
                update_values.append(value)
        
        if not update_fields:
            return {'statusCode': 400, 'body': json.dumps({'message': 'No valid fields to update provided.'})}

        update_values.append(employee_id)
        sql = f"UPDATE employees SET {', '.join(update_fields)} WHERE id = %s;"

        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute(sql, tuple(update_values))
            if cur.rowcount == 0:
                return {'statusCode': 404, 'body': json.dumps({'message': 'Employee not found.'})}
            conn.commit()
        
        logger.info(f"Successfully updated employee with ID: {employee_id}")
        return {'statusCode': 200, 'body': json.dumps({'message': 'Employee updated successfully.'})}
    except (psycopg2.errors.UniqueViolation):
        return {'statusCode': 409, 'body': json.dumps({'message': 'The provided email already exists for another employee.'})}
    finally:
        if conn: conn.close()

def handle_delete_employee(event):
    conn = None
    try:
        body = json.loads(event.get('body', '{}'))
        employee_id = body.get('employee_id')
        if not employee_id:
            return {'statusCode': 400, 'body': json.dumps({'message': 'employee_id is missing from request body.'})}

        conn = get_db_connection()
        sql = "DELETE FROM employees WHERE id = %s;"
        with conn.cursor() as cur:
            cur.execute(sql, (employee_id,))
            if cur.rowcount == 0:
                return {'statusCode': 404, 'body': json.dumps({'message': 'Employee not found.'})}
            conn.commit()

        logger.info(f"Successfully deleted employee with ID: {employee_id}")
        return {'statusCode': 204, 'body': ''}
    finally:
        if conn: conn.close()

# =================================================================================
# MAIN LAMBDA HANDLER
# =================================================================================

def lambda_handler(event, context):
    try:
        # Defensive access to HTTP method
        http_method = None
        if 'requestContext' in event and 'http' in event['requestContext']:
            http_method = event['requestContext']['http'].get('method')
        else:
            logger.error("Malformed event: missing requestContext.http")
            return _response(400, {'message': 'Malformed event: missing requestContext.http'})

        path = event.get('rawPath') or event.get('path') or ''
        logger.info(f"Received {http_method} request for path {path}")

        if http_method == 'OPTIONS':
            return _response(200, {'message': 'CORS preflight OK'})

        # You can route based on path, if you plan to extend
        if path.startswith('/employee'):
            if http_method == 'POST':
                return handle_create_employee(event)
            elif http_method == 'GET':
                return handle_read_employee(event)
            elif http_method == 'PUT':
                return handle_update_employee(event)
            elif http_method == 'DELETE':
                return handle_delete_employee(event)
            else:
                return _response(405, {'message': f'Method {http_method} is not supported on {path}.'})
        else:
            return _response(404, {'message': f'Path {path} not found.'})

    except Exception as e:
        logger.error(f"An unhandled error occurred in lambda_handler: {str(e)}")
        return _response(500, {'message': 'Internal Server Error'})
