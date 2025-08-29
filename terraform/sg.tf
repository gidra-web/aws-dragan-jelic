resource "aws_security_group" "asg_sg" {
  name        = "${var.acc}-asg-sg"
  description = "Allow traffic from ALB to EC2 in ASG"
  vpc_id      = aws_vpc.dragan_vpc.id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.acc}-asg-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.acc}-alb-sg"
  description = "Allow public HTTP/HTTPS access to ALB"
  vpc_id      = aws_vpc.dragan_vpc.id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.acc}-alb-sg"
  }
}


# -------------------------
#  Aurora Security Group
# -------------------------
resource "aws_security_group" "aurora_sg" {
  name        = "${var.acc}-aurora-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = aws_vpc.dragan_vpc.id

  tags = {
    Name = "${var.acc}-aurora-sg"
  }
}

resource "aws_security_group" "vpc_lambda_sg" {
  name        = "${var.acc}-vpc-lambda-sg"
  description = "Security group for all VPC-based Lambda functions"
  vpc_id      = aws_vpc.dragan_vpc.id

  tags = {
    Name = "${var.acc}-vpc-lambda-sg"
  }
}

resource "aws_security_group_rule" "lambda_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound HTTPS to internet"
}

# Lambda -> Aurora (outbound from Lambda)
resource "aws_security_group_rule" "lambda_egress_to_aurora" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_lambda_sg.id
  source_security_group_id = aws_security_group.aurora_sg.id
  description              = "Allow outbound PostgreSQL to Aurora"
}

# Aurora <- Lambda (inbound to Aurora)
resource "aws_security_group_rule" "aurora_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora_sg.id
  source_security_group_id = aws_security_group.vpc_lambda_sg.id
  description              = "Allow inbound PostgreSQL from Lambda"
}

# Lambda -> Internet (HTTPS, e.g., CloudWatch/SSM)
resource "aws_security_group_rule" "lambda_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.vpc_lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound HTTPS to VPC endpoint"
}

# Lambda -> Internet (catch-all optional)
resource "aws_security_group_rule" "lambda_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.vpc_lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic (fallback)"
}
