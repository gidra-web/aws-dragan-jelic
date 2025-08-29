resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dragan_vpc.id

  tags = {
    Name = "${var.project_prefix}-igw-${var.aws_region}"
  }
}

resource "aws_vpc" "dragan_vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.acc}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = var.public_sb_ls

  vpc_id                  = aws_vpc.dragan_vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_prefix}-public-${each.value.az}"
  }
}
resource "aws_subnet" "private" {
  for_each = var.private_sb_ls

  vpc_id            = aws_vpc.dragan_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_prefix}-private-${each.value.az}"
  }
}

resource "aws_subnet" "data" {
  for_each = var.data_sb_ls

  vpc_id            = aws_vpc.dragan_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_prefix}-data-${each.value.az}"
  }
}

#Route Tables IGW
resource "aws_route_table" "igw_rt" {
  vpc_id = aws_vpc.dragan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_prefix}-routing-table-public"
  }
}
resource "aws_route_table" "private_subnet_rt" {
  vpc_id = aws_vpc.dragan_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_prefix}-routing-table-private"
  }
}
resource "aws_route_table" "data_subnet_rt" {
  vpc_id = aws_vpc.dragan_vpc.id

  tags = {
    Name = "${var.project_prefix}-routing-table-db"
  }
}

#Route Table Associations
resource "aws_route_table_association" "public_subnet_igw_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.igw_rt.id
}

resource "aws_route_table_association" "private_subnet_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_subnet_rt.id
}

resource "aws_route_table_association" "data_subnet_rt_assoc" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data_subnet_rt.id
}
