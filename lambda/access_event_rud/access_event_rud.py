import json
import os
import boto3 #type: ignore
import decimal
from boto3.dynamodb.conditions import Key #type: ignore

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

# Convert DynamoDB Decimals to int/float
def decimal_to_native(obj):
    if isinstance(obj, list):
        return [decimal_to_native(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: decimal_to_native(v) for k, v in obj.items()}
    elif isinstance(obj, decimal.Decimal):
        if obj % 1 == 0:
            return int(obj)
        else:
            return float(obj)
    else:
        return obj

# Setup DynamoDB Table Resource
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE_NAME']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    if 'requestContext' in event and 'http' in event['requestContext']:
        method = event['requestContext']['http']['method']
        route_key = event['routeContext']['routeKey']
    else:
        method = event.get('httpMethod')
        route_key = f"{method} {event.get('resource')}"

    if method == 'OPTIONS':
        return _response(200, {'message': 'CORS preflight OK'})

    query_params = event.get('queryStringParameters') or {}

    body = event.get('body')
    if body:
        try:
            body = json.loads(body)
        except Exception as e:
            return _response(400, {'message': f'Invalid JSON body: {str(e)}'})
    else:
        body = {}

    if method == 'GET':
        return handle_get(route_key, body, query_params)
    elif method == 'PUT':
        return handle_put(body)
    elif method == 'DELETE':
        return handle_delete(body)
    else:
        return _response(405, {'message': 'Method Not Allowed'})

def handle_get(route_key, body, query_params):
    if route_key == "GET /events":
        token_id = query_params.get('token') or body.get('token_id')
        timestamp = query_params.get('timestamp') or body.get('timestamp')

        if token_id and timestamp is not None:
            try:
                response = table.get_item(
                    Key={
                        'token_id': token_id,
                        'timestamp': int(timestamp)
                    }
                )
                item = response.get('Item')
                if item:
                    return _response(200, decimal_to_native(item))
                else:
                    return _response(404, {'message': 'Event not found'})
            except Exception as e:
                return _response(500, {'message': f'Error retrieving event: {str(e)}'})

        elif token_id:
            try:
                response = table.query(
                    KeyConditionExpression=Key('token_id').eq(token_id)
                )
                items = decimal_to_native(response.get('Items', []))
                return _response(200, items)
            except Exception as e:
                return _response(500, {'message': f'Error retrieving events for token_id {token_id}: {str(e)}'})

        else:
            try:
                response = table.scan()
                items = decimal_to_native(response.get('Items', []))
                return _response(200, items)
            except Exception as e:
                return _response(500, {'message': f'Error retrieving all events: {str(e)}'})
    else:
        return _response(404, {'message': 'GET route not supported'})

def handle_put(body):
    token_id = body.get('token_id')
    timestamp = body.get('timestamp')
    authorized = body.get('authorized')

    if not token_id or timestamp is None or authorized is None:
        return _response(400, {'message': 'token_id, timestamp, and authorized are required in the request body'})

    item = {
        'token_id': token_id,
        'timestamp': int(timestamp),
        'authorized': bool(authorized)
    }

    try:
        table.put_item(Item=item)
        return _response(200, {'message': 'Event stored successfully', 'item': item})
    except Exception as e:
        return _response(500, {'message': f'Failed to store event: {str(e)}'})

def handle_delete(body):
    token_id = body.get('token_id')

    if not token_id:
        return _response(400, {'message': 'token_id is required in the request body'})

    try:
        events = table.query(
            KeyConditionExpression=Key('token_id').eq(token_id)
        ).get('Items', [])

        with table.batch_writer() as batch:
            for event_item in events:
                batch.delete_item(
                    Key={
                        'token_id': token_id,
                        'timestamp': event_item['timestamp']
                    }
                )

        return _response(200, {'message': f'Deleted {len(events)} events for token_id {token_id}'})
    except Exception as e:
        return _response(500, {'message': f'Failed to delete events for token_id {token_id}: {str(e)}'})

def _response(status, body):
    return {
        'statusCode': status,
        'headers': { "Content-Type": "application/json" },
        'body': json.dumps(body)
    }

