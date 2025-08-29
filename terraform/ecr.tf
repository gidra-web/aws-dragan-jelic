resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${var.acc}-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.acc}-ecr-repo"
  }
}