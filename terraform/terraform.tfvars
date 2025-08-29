aws_region         = "eu-central-1"
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
vpc_cidr_block     = "10.2.0.0/16"
acc                = "dragan"
project_prefix     = "draganDevoT"

private_sb_ls = {
  "private-subnet-1a" = { cidr_block = "10.2.0.0/24", az = "eu-central-1a" },
  "private-subnet-1b" = { cidr_block = "10.2.1.0/24", az = "eu-central-1b" },
  "private-subnet-1c" = { cidr_block = "10.2.2.0/24", az = "eu-central-1c" }
}

data_sb_ls = {
  "db-subnet-1a" = { cidr_block = "10.2.3.0/24", az = "eu-central-1a" },
  "db-subnet-1b" = { cidr_block = "10.2.4.0/24", az = "eu-central-1b" },
  "db-subnet-1c" = { cidr_block = "10.2.5.0/24", az = "eu-central-1c" }
}

public_sb_ls = {
  "public-subnet-1a" = { cidr_block = "10.2.6.0/24", az = "eu-central-1a" },
  "public-subnet-1b" = { cidr_block = "10.2.7.0/24", az = "eu-central-1b" },
  "public-subnet-1c" = { cidr_block = "10.2.8.0/24", az = "eu-central-1c" }
}

asg_min     = 1
asg_max     = 3
asg_desired = 2

subdomain_name = "dragan.stilltesting.xyz"

#ami-img = "ami-08aa372c213609089" 