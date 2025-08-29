provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::352003904348:role/DraganJRole"
  }

  //sijsfsdsasdaa2311

  default_tags {
    tags = {
      Project = var.project_prefix
    }
  }
}
