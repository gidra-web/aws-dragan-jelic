resource "aws_eip" "nateip" {
  domain = "vpc"
  tags = {
    Name = "${var.acc}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nateip.id
  subnet_id     = aws_subnet.public["public-subnet-1a"].id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.acc}-nat-gw"
  }

}