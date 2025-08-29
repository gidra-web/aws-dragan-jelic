resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.acc}-user-pool"

  username_attributes = ["email"]

  password_policy {
    minimum_length    = 6
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  mfa_configuration = "OPTIONAL"
  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }


  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
    string_attribute_constraints {
      min_length = 6
      max_length = 256
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  tags = {
    Name = "${var.acc}-user-pool"
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name            = "${var.acc}-user-pool-client"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
}