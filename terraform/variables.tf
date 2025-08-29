variable "aws_region" {}

variable "vpc_cidr_block" {}

variable "private_sb_ls" {
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "data_sb_ls" {
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "public_sb_ls" {
  type = map(object({
    cidr_block = string
    az         = string
  }))
}

variable "availability_zones" { type = list(string) }

variable "acc" {}

variable "project_prefix" {}

variable "asg_min" {}

variable "asg_max" {}

variable "asg_desired" {}

variable "subdomain_name" {}