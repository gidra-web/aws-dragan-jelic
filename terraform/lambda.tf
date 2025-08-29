data "aws_ssm_parameter" "api_key" {
  name            = "dragan-api-key"
  with_decryption = true
}

data "archive_file" "eh_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/event_handler"
  output_path = "${path.module}/../lambda/event_handler.zip"
}

data "archive_file" "auth_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/custom_auth"
  output_path = "${path.module}/../lambda/custom_auth.zip"
}

data "archive_file" "employee_crud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/employee_crud"
  output_path = "${path.module}/../lambda/employee_crud.zip"
}

data "archive_file" "token_crud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/token_crud"
  output_path = "${path.module}/../lambda/token_crud.zip"
}

data "archive_file" "event_rud_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/access_event_rud"
  output_path = "${path.module}/../lambda/access_event_rud.zip"
}

data "archive_file" "schema_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/lambda_schema"
  output_path = "${path.module}/../lambda/lambda_schema.zip"
}

resource "aws_lambda_function" "eh_lambda" {
  function_name = "${var.acc}-eh_lambda"
  handler       = "event_handler.lambda_handler"
  runtime       = "python3.9"
  #role          = aws_iam_role.lambda_exec_role.arn
  role = aws_iam_role.lambda_iot_access_event_handler_role.arn

  filename         = data.archive_file.eh_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.eh_zip.output_path)

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.access_events.name
    }
  }
  tags = {
    Name = "${var.acc}-eh-lambda"
  }
}

resource "aws_lambda_function" "custom_auth" {
  function_name = "${var.acc}-custom-auth-lambda"
  handler       = "custom-auth.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.authorizer_lambda_role.arn

  filename         = data.archive_file.auth_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.auth_zip.output_path)

  tags = {
    Name = "${var.acc}-auth-lambda"
  }

  environment {
    variables = {
      API_KEY_PARAMETER_NAME = "${var.acc}-api-key"
    }
  }
}


resource "aws_lambda_function" "event_rud_func" {
  filename         = data.archive_file.event_rud_zip.output_path
  function_name    = "${var.acc}-event-rud"
  role             = aws_iam_role.event_rud_role.arn
  handler          = "access_event_rud.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.event_rud_zip.output_path)
  runtime          = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.access_events.name
    }
  }

  tags = {
    Name = "${var.project_prefix}-event-rud"
  }
}

resource "aws_lambda_function" "employee_crud_lambda" {
  filename         = data.archive_file.employee_crud_zip.output_path
  function_name    = "${var.acc}-employee-crud-lambda"
  role             = aws_iam_role.crud_vpc_lambda_role.arn
  handler          = "employee_crud.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.employee_crud_zip.output_path)
  runtime          = "python3.9"
  timeout          = 20

  layers = [aws_lambda_layer_version.psycopg2_layer.arn]


  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_creds.arn
    }
  }

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.data : subnet.id]
    security_group_ids = [aws_security_group.vpc_lambda_sg.id]
  }

  tags = {
    Name = "${var.acc}-employee-crud-lambda"
  }
}

resource "aws_lambda_function" "token_crud_lambda" {
  filename         = data.archive_file.token_crud_zip.output_path
  function_name    = "${var.acc}-token-crud-lambda"
  role             = aws_iam_role.crud_vpc_lambda_role.arn
  handler          = "token_crud.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.employee_crud_zip.output_path)
  runtime          = "python3.9"
  timeout          = 20

  layers = [aws_lambda_layer_version.psycopg2_layer.arn]

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_creds.arn
    }
  }

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.data : subnet.id]
    security_group_ids = [aws_security_group.vpc_lambda_sg.id]
  }


  tags = {
    Name = "${var.acc}-employee-crud-lambda"
  }
}

resource "aws_lambda_function" "schema_loader" {
  function_name    = "${var.project_prefix}-schema-loader"
  filename         = data.archive_file.schema_zip.output_path
  handler          = "lambda_schema.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.crud_vpc_lambda_role.arn
  source_code_hash = filebase64sha256(data.archive_file.schema_zip.output_path)
  timeout          = 20

  environment {
    variables = {
      DB_SECRET_ARN = aws_secretsmanager_secret.db_creds.arn
    }
  }

  vpc_config {
    subnet_ids         = [for subnet in aws_subnet.data : subnet.id]
    security_group_ids = [aws_security_group.vpc_lambda_sg.id]
  }

  layers = [aws_lambda_layer_version.psycopg2_layer.arn]

}


resource "aws_lambda_layer_version" "psycopg2_layer" {
  filename            = "./lambda_layer/psycopg2-layer.zip"
  layer_name          = "${var.project_prefix}-psycopg2-layer"
  compatible_runtimes = ["python3.9"]

  source_code_hash = filebase64sha256("./lambda_layer/psycopg2-layer.zip")
}