terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "dragan-s3-terraform-state"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
    assume_role = {
      role_arn = "arn:aws:iam::352003904348:role/DraganJRole"
    }
  }
}