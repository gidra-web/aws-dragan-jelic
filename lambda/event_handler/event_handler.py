import json
import os
import boto3  # type: ignore

dynamodb = boto3.client('dynamodb')
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')


def lambda_handler(event, context):
    print(f"Received SQS event with {len(event.get('Records', []))} records.")

    if not DYNAMODB_TABLE_NAME:
        error_message = "Error: DYNAMODB_TABLE_NAME environment variable is not set."
        print(error_message)
        return _response(500, {'message': error_message})

    processed_count = 0
    failed_message_ids = []

    for record in event.get('Records', []):
        message_id = record.get('messageId', 'unknown-id')
        try:
            message_body_str = record.get('body', '{}')
            request_data = json.loads(message_body_str)

            print(f"Processing SQS message ID: {message_id}, Body: {request_data}")

            token_id = request_data.get('token')
            timestamp = request_data.get('timestamp')
            authorized = request_data.get('authorized')

            if not token_id or timestamp is None or authorized is None:
                print(f"Skipping SQS message ID: {message_id} due to missing fields: {request_data}")
                failed_message_ids.append(message_id)
                continue

            item = {
                'token_id': {'S': str(token_id)},
                'timestamp': {'N': str(int(timestamp))},  # ensures numeric value
                'authorized': {'BOOL': bool(authorized)},
            }

            dynamodb.put_item(
                TableName=DYNAMODB_TABLE_NAME,
                Item=item
            )

            print(f"Stored item successfully: token_id={token_id}, message_id={message_id}")
            processed_count += 1

        except json.JSONDecodeError:
            print(f"Invalid JSON in message body for message ID: {message_id}. Body: {record.get('body')}")
            failed_message_ids.append(message_id)
        except Exception as e:
            print(f"Error processing message ID {message_id}: {e}")
            failed_message_ids.append(message_id)

    summary = {
        'message': f'Processed: {processed_count}, Failed: {len(failed_message_ids)}',
        'failedMessageIds': failed_message_ids
    }

    print("Batch processing complete:", summary)
    return _response(200, summary)


def _response(status_code, body):
    """Standard JSON response with optional CORS headers."""
    return {
        'statusCode': status_code,
        'headers': {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",  # Optional, remove if only for SQS
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        },
        'body': json.dumps(body)
    }
