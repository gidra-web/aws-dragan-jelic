resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.acc}-ec2-instance-role"

  #ec2 assume role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    name = "${var.acc}-ec2-instance-role"
  }
}
resource "aws_iam_role_policy_attachment" "cw_logs" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# ------------------------------IAM Instance Profile------------------------------

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.acc}-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
  tags = {
    Name = "${var.acc}-ec2-instance-profile"
  }
}

# ------------------------------IAM Roles for ECR Access, Push, Pull------------------------------
##PUSH
resource "aws_iam_role" "ecr_push_role" {
  name = "${var.acc}-ecr-push-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowGithubOIDCToAssume",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::654431520045:role/DevoteamGitHubOIDCRole"
        },
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name = "${var.acc}-ecr-push-role"
  }
}

resource "aws_iam_policy" "ecr_push_policy" {
  name        = "${var.acc}-ECRPushAccessPolicy"
  description = "Allows pushing Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowECRLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "AllowECRPush"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.ecr_repo.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_push_attachment" {
  role       = aws_iam_role.ecr_push_role.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}


##PULL
resource "aws_iam_role" "ecr_pull_role" {
  name = "${var.acc}-ecr-pull-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.acc}-ecr-pull-role"
  }
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name        = "${var.acc}-ECRPullAccessPolicy"
  description = "Allows EC2 instance to pull Docker images from ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECRLogin"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECRImagePull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = aws_ecr_repository.ecr_repo.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_pull_attachment" {
  role       = aws_iam_role.ecr_pull_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}
# ------------------------------IAM Role for Lambda Execution------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.acc}-custom-authorizer-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.acc}-custom-authorizer-lambda-role"
  }
}

# IAM Lambda Authorizer Role
resource "aws_iam_role" "authorizer_lambda_role" {
  name = "${var.acc}-api_gateway_authorizer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "authorizer_lambda_basic_execution" {
  role       = aws_iam_role.authorizer_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_read" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

# IAM Policy for the Lambda Authorizer (to access Parameter Store and CloudWatch Logs)
resource "aws_iam_role_policy" "authorizer_lambda_policy" {
  name = "api_gateway_authorizer_lambda_policy"
  role = aws_iam_role.authorizer_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = data.aws_ssm_parameter.api_key.arn # Grant access only to the specific parameter
      },
      {
        Action = [
          "dynamodb:PutItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.access_events.arn
      }
    ]
  })
}


# # ------------------------------IAM Policy for API GW to SQS------------------------------


# Permissions: Lambda can read from SQS
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda_sqs_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.iot_event_queue.arn
      }
    ]
  })
}


# IAM API-GW to SQS Role
resource "aws_iam_role" "apigw_sqs_role" {
  name = "${var.acc}-api-gw-sqs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Define the SQS SendMessage policy as a managed policy
resource "aws_iam_policy" "apigateway_sqs_send_message_managed_policy" {
  name        = "${var.acc}-APIGatewaySQSSendMessagePolicy"
  description = "Allows API Gateway to send messages to the IoT SQS queue"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.iot_event_queue.arn
      }
    ]
  })
}

# Attach the managed SQS SendMessage policy to the API Gateway's SQS access role
resource "aws_iam_role_policy_attachment" "apigateway_sqs_send_message_attachment" {
  role       = aws_iam_role.apigw_sqs_role.name
  policy_arn = aws_iam_policy.apigateway_sqs_send_message_managed_policy.arn
}

# --------------------- Dynamodb IAM -----------------------------

resource "aws_iam_role" "lambda_iot_access_event_handler_role" {
  name = "${var.acc}-lambda-iot-access-event-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for DynamoDB PutItem permission
resource "aws_iam_policy" "dynamodb_put_policy" {
  name        = "${var.acc}-dynamodb-put-policy"
  description = "Allows Lambda to put items into the specific DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.access_events.arn # References the DynamoDB table from main.tf
      }
    ]
  })
}

# Policy for SQS message consumption permissions
resource "aws_iam_policy" "receive_messages_policy" {
  name = "${var.project_prefix}-sqs-receive-messages-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.iot_event_queue.arn
      }
    ]
  })
}


# Attach the DynamoDB put policy
resource "aws_iam_role_policy_attachment" "dynamodb_put_policy_attachment" {
  role       = aws_iam_role.lambda_iot_access_event_handler_role.name
  policy_arn = aws_iam_policy.dynamodb_put_policy.arn
}

# Attach the SQS receive messages policy
resource "aws_iam_role_policy_attachment" "receive_messages_policy_attachment" {
  role       = aws_iam_role.lambda_iot_access_event_handler_role.name
  policy_arn = aws_iam_policy.receive_messages_policy.arn
}

# Attach the AWS managed basic execution role for CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_policy_attachment" {
  role       = aws_iam_role.lambda_iot_access_event_handler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------- RUD ------------------------------
resource "aws_iam_role" "event_rud_role" {
  name = "${var.project_prefix}-event-rud-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for full RUD access to the DynamoDB table
resource "aws_iam_policy" "dynamodb_full_access_policy" {
  name = "${var.project_prefix}-dynamodb-full-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:BatchGetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable"
        ],
        Resource = [
          aws_dynamodb_table.access_events.arn,
          "${aws_dynamodb_table.access_events.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_full_access_attach" {
  role       = aws_iam_role.event_rud_role.name
  policy_arn = aws_iam_policy.dynamodb_full_access_policy.arn
}

##ssm

# Attach custom policy for reading DB credentials from SSM
resource "aws_iam_policy" "crud_ssm_policy" {
  name        = "${var.acc}-employee-crud-ssm-policy"
  description = "Allow Lambda to read DB secrets from SSM"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Effect = "Allow",
        Resource = [
          data.aws_ssm_parameter.db_username.arn,
          data.aws_ssm_parameter.db_pass.arn
        ]
      }
    ]
  })
}

##vpc lambda
resource "aws_iam_role" "crud_vpc_lambda_role" {
  name = "${var.acc}-crud-vpc-lambda-role"

  # Trust policy
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for Lambda VPC ENI management (as provided previously)
resource "aws_iam_policy" "lambda_vpc_network_policy" {
  name        = "${var.acc}-lambda-vpc-network-policy"
  description = "Allows Lambda to manage ENIs for VPC connectivity"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.acc}-lambda-vpc-network-policy"
  }
}

# IAM Policy to allow Lambda to connect to Aurora RDS
resource "aws_iam_policy" "lambda_rds_connect_policy" {
  name        = "${var.acc}-lambda-rds-connect-policy"
  description = "Allows Lambda to connect to Aurora RDS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds-db:connect"
        ],

        Resource = "arn:aws:rds-db:${var.aws_region}:${var.acc}:dbuser:${aws_rds_cluster.aurora_cluster.cluster_resource_id}/*"
      }
    ]
  })

  tags = {
    Name = "${var.acc}-lambda-rds-connect-policy"
  }
}

# Attach the basic Lambda execution policy to the role
resource "aws_iam_role_policy_attachment" "crud_tokens_lambda_exec_policy" {
  role       = aws_iam_role.crud_vpc_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "schema_vpc_access" {
  role       = aws_iam_role.crud_vpc_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach the VPC network policy to the crud_vpc_lambda_role
resource "aws_iam_role_policy_attachment" "crud_tokens_lambda_vpc_attachment" {
  role       = aws_iam_role.crud_vpc_lambda_role.name
  policy_arn = aws_iam_policy.lambda_vpc_network_policy.arn
}

resource "aws_iam_role_policy_attachment" "crud_vpc_lambda_ssm_policy_attachment" {
  role       = aws_iam_role.crud_vpc_lambda_role.name
  policy_arn = aws_iam_policy.crud_ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "crud_vpc_lambda_rds_connect_attachment" {
  role       = aws_iam_role.crud_vpc_lambda_role.name
  policy_arn = aws_iam_policy.lambda_rds_connect_policy.arn
}


resource "aws_iam_role_policy" "allow_secretsmanager_get" {
  name = "allow-secretsmanager-get"
  role = aws_iam_role.crud_vpc_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "secretsmanager:GetSecretValue",
        Resource = "arn:aws:secretsmanager:eu-central-1:352003904348:secret:dragan/rds/db-credentials*"
      }
    ]
  })
}
