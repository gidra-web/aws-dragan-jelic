resource "aws_apigatewayv2_api" "http_api_gateway" {
  name          = "${var.acc}-http-api"
  protocol_type = "HTTP"

  tags = {
    Name = "${var.acc}-http-api"
  }

  cors_configuration {
  allow_origins = ["*"]
  allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  allow_headers = ["Content-Type", "Authorization"]
}
}


resource "aws_apigatewayv2_stage" "apig_stage" {
  api_id      = aws_apigatewayv2_api.http_api_gateway.id
  name        = "${var.acc}-prod-stage"
  auto_deploy = true

  tags = {
    Name = "${var.acc}-prod-stage"
  }
}

# ---------------- API Gateway Custom Authorizer --------------

resource "aws_apigatewayv2_authorizer" "iot_auth" {
  api_id          = aws_apigatewayv2_api.http_api_gateway.id
  authorizer_type = "REQUEST"
  authorizer_uri  = aws_lambda_function.custom_auth.invoke_arn

  name             = "${var.acc}--iot-event-authorizer"
  identity_sources = ["$request.header.Authorization"]

  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

# ------------------ API Gateway ~ Cognito ----------------
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = aws_apigatewayv2_api.http_api_gateway.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.acc}-cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.client.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  }
}

# ------------------------------------------------------------- #

#Integration for Lambda with access events
resource "aws_apigatewayv2_integration" "apigw-sqs-integration" {
  api_id              = aws_apigatewayv2_api.http_api_gateway.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  credentials_arn     = aws_iam_role.apigw_sqs_role.arn


  request_parameters = {
    "QueueUrl"       = aws_sqs_queue.iot_event_queue.id,
    "MessageBody"    = "$request.body",
    "MessageGroupId" = "dragan-iot-event-group",
  }
}

resource "aws_apigatewayv2_integration" "event_rud_lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.event_rud_func.invoke_arn
}

resource "aws_apigatewayv2_integration" "employee_api_integration" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.employee_crud_lambda.invoke_arn
  integration_method = "POST"
}
#CRUD Employee lambda integration
resource "aws_apigatewayv2_integration" "crud_tokens_lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.token_crud_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke_auth" {
  statement_id  = "AllowAPIGatewayInvokeCustomAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api_gateway.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.iot_auth.id}"
}

resource "aws_lambda_permission" "sqs_to_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eh_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.iot_event_queue.arn
}

resource "aws_lambda_permission" "api_gw_to_invoke_rud_lambda" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_rud_func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "crud_employee_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.employee_crud_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api_gateway.execution_arn}/*/*"
}

# Grant API Gateway permission to invoke CRUD tokens
resource "aws_lambda_permission" "crud_tokens_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.token_crud_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api_gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "iot_access_event_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "POST /iot/event"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.iot_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.apigw-sqs-integration.id}"
}
resource "aws_apigatewayv2_route" "event_get_rud" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "GET /events"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.event_rud_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "event_delete_rud" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "DELETE /events"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.event_rud_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "employee_get_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "GET /employee"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.employee_api_integration.id}"
}

resource "aws_apigatewayv2_route" "employee_post_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "POST /employee"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.employee_api_integration.id}"
}
resource "aws_apigatewayv2_route" "employee_put_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "PUT /employee"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.employee_api_integration.id}"
}
resource "aws_apigatewayv2_route" "employee_delete_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "DELETE /employee"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.employee_api_integration.id}"
}

# Route for ANY /token
resource "aws_apigatewayv2_route" "tokens_get_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "GET /token" # Specific route for DELETE requests
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.crud_tokens_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "tokens_post_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "POST /token" # Specific route for DELETE requests
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.crud_tokens_lambda_integration.id}"
}
resource "aws_apigatewayv2_route" "tokens_put_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "PUT /token" # Specific route for DELETE requests
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.crud_tokens_lambda_integration.id}"
}
resource "aws_apigatewayv2_route" "tokens_delete_route" {
  api_id             = aws_apigatewayv2_api.http_api_gateway.id
  route_key          = "DELETE /token" # Specific route for DELETE requests
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  authorization_type = "JWT"

  target = "integrations/${aws_apigatewayv2_integration.crud_tokens_lambda_integration.id}"
}

# ----------- Domain Name for API Gateway -----------

resource "aws_apigatewayv2_domain_name" "api_custom_subdomain" {
  domain_name = "api.${var.subdomain_name}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = {
    Name = "api-gateway-custom-subdomain"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.http_api_gateway.id
  domain_name = aws_apigatewayv2_domain_name.api_custom_subdomain.id
  stage       = aws_apigatewayv2_stage.apig_stage.id
}


#Frontend JS → http://your-frontend.com/employee → NGINX → https://api.dragan.stilltesting.xyz