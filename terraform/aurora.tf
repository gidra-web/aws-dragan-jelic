data "aws_ssm_parameter" "db_username" {
  name = "${var.acc}-aurora-username"
}
data "aws_ssm_parameter" "db_pass" {
  name = "${var.acc}-aurora-password"
  with_decryption = true
}


resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "${var.acc}-aurora-cluster"
  engine                  = "aurora-postgresql"
  database_name           = "dragandb"
  master_username         = data.aws_ssm_parameter.db_username.value
  master_password         = data.aws_ssm_parameter.db_pass.value
  skip_final_snapshot     = true
  backup_retention_period = 4
  port                   = 5432

  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name

  tags = {
    Name = "${var.project_prefix}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  count              = 2
  identifier         = "${var.acc}-aurora-cluster-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}


resource "aws_db_subnet_group" "aurora_subnet_group" {
  name = "${var.acc}-db-subnet-group"

  subnet_ids = [for subnet in aws_subnet.data : subnet.id]

  tags = {
    Name = "${var.project_prefix}-db-subnet-group"
  }
}

