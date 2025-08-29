import boto3  # type: ignore
import logging

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize SSM client outside the handler for re-use
ssm = boto3.client('ssm')

def lambda_handler(event, context):
    logger.info("Authorizer triggered. Event received.")

    # Extract the token directly (no "Bearer " prefix expected)
    token = event.get("headers", {}).get("authorization")
    if not token:
        logger.warning("Missing Authorization header.")
        return {"isAuthorized": False}

    try:
        response = ssm.get_parameter(
            Name='dragan-api-key',
            WithDecryption=True
        )
        expected_token = response['Parameter']['Value']
    except Exception as e:
        logger.error("Failed to retrieve token from SSM: %s", str(e))
        return {"isAuthorized": False}

    # Compare tokens directly
    if token == expected_token:
        logger.info("Authorization successful.")
        return {"isAuthorized": True}
    else:
        logger.warning("Authorization failed: Invalid token.")
        return {"isAuthorized": False
    }
