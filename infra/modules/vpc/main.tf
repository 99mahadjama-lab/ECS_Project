#VPC
resource "aws_vpc" "IT-Tools_VPC" {
  cidr_block           = "10.0.0.0/24"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name               = "IT-Tools_VPC"
    Project            = var.project_tag
  }
}
#Subnets
resource "aws_subnet" "Private_Subnet_1" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  cidr_block           = "10.0.0.0/26"
  availability_zone    = "eu-west-2a"
  tags = {
    Name               = "Private_Subnet_1"
    Project            = var.project_tag
  }
}

resource "aws_subnet" "Private_Subnet_2" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  cidr_block           = "10.0.0.64/26"
  availability_zone    = "eu-west-2b"
  tags = {
    Name               = "Private_Subnet_2"
    Project            = var.project_tag
  }
}

resource "aws_subnet" "Public_Subnet_1" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  cidr_block           = "10.0.0.128/26"
  availability_zone    = "eu-west-2a"
  tags = {
    Name               = "Public_Subnet_1"
    Project            = var.project_tag
  }
}

resource "aws_subnet" "Public_Subnet_2" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  cidr_block           = "10.0.0.192/26"
  availability_zone    = "eu-west-2b"
  tags = {
    Name               = "Public_Subnet_2"
    Project            = var.project_tag
  }
}
#Internet Gateway
resource "aws_internet_gateway" "IT-Tools_IGW" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  tags = {
    Name               = "IT-Tools_IGW"
    Project            = var.project_tag
  }
}
#Nat Gateway
resource "aws_nat_gateway" "IT-Tools_NGW" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  availability_mode    = "regional"
}
#Route Tables
resource "aws_route_table" "Public_Route" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  route {
    cidr_block         = "0.0.0.0/0"
    gateway_id         = aws_internet_gateway.IT-Tools_IGW.id
  }
  tags = {
    Name               = "Public_Route"
    Project            = var.project_tag
  }
}
resource "aws_route_table" "Private_Route" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  route {
    cidr_block         = "0.0.0.0/0"
    nat_gateway_id     = aws_nat_gateway.IT-Tools_NGW.id
  }
  tags = {
    Name               = "Private_Route"
    Project            = var.project_tag
  }
}
#Route Association
resource "aws_route_table_association" "Private_AS1" {
  subnet_id            = aws_subnet.Private_Subnet_1.id
  route_table_id       = aws_route_table.Private_Route.id
}
resource "aws_route_table_association" "Private_AS2" {
  subnet_id            = aws_subnet.Private_Subnet_2.id
  route_table_id       = aws_route_table.Private_Route.id
}
resource "aws_route_table_association" "Public_AS1" {
  subnet_id            = aws_subnet.Public_Subnet_1.id
  route_table_id       = aws_route_table.Public_Route.id
}
resource "aws_route_table_association" "Public_AS2" {
  subnet_id            = aws_subnet.Public_Subnet_2.id
  route_table_id       = aws_route_table.Public_Route.id
}

