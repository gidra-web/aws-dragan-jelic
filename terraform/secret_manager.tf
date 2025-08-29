resource "aws_secretsmanager_secret" "db_creds" {
  name        = "${var.acc}/rds/db-credentials"
  description = "Credentials for Aurora PostgreSQL db"
}

resource "aws_secretsmanager_secret_version" "db_creds_version" {
  secret_id = aws_secretsmanager_secret.db_creds.id

  secret_string = jsonencode({
    DB_HOST     = aws_rds_cluster.aurora_cluster.endpoint
    DB_PORT     = aws_rds_cluster.aurora_cluster.port
    DB_NAME     = aws_rds_cluster.aurora_cluster.database_name
    DB_USER     = data.aws_ssm_parameter.db_username.value
    DB_PASSWORD = data.aws_ssm_parameter.db_pass.value
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id       = aws_vpc.dragan_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for subnet in aws_subnet.data : subnet.id]
  security_group_ids = [aws_security_group.vpc_lambda_sg.id]  # allow HTTPS (port 443)

  private_dns_enabled = true  # Allows `secretsmanager.<region>.amazonaws.com` to resolve to internal IPs#
}
