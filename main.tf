
provider "aws" {
  region     = "eu-west-1"
  access_key = "AKIA6QJIPADQS5ZJR3QW"
  secret_key = "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"
}

data "aws_availability_zones" "available" {

}




resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-test-igw"
  }
}


resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-test-public-route"
  }
}

resource "aws_default_route_table" "private_route" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = "my-private-route-table"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  cidr_block              = var.public_cidrs[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "my-test-public-subnet.${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  cidr_block        = var.private_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "my-test-private-subnet.${count.index + 1}"
  }
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_subnet_assoc" {
  count          = 2
  route_table_id = aws_route_table.public_route.id
  subnet_id      = aws_subnet.public_subnet.*.id[count.index]
  depends_on     = [aws_route_table.public_route, aws_subnet.public_subnet]
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_subnet_assoc" {
  count          = 2
  route_table_id = aws_default_route_table.private_route.id
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  depends_on     = [aws_default_route_table.private_route, aws_subnet.private_subnet]
}

resource "aws_security_group" "my-test-sg" {
  name   = "my-test-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow-ssh" {
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.my-test-sg.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow-outbound" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.my-test-sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}



resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "my-new-test-vpc"
  }
}













