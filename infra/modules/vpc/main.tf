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
resource "aws_subnet" "Subnets" {
  for_each             = local.subnets
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  cidr_block           = each.value.cidr_block
  availability_zone    = each.value.availability_zone
  tags = {
    Name               = each.value.name
    Project            = var.project_tag
  }
}
# #Internet Gateway
resource "aws_internet_gateway" "IT-Tools_IGW" {
  vpc_id               = aws_vpc.IT-Tools_VPC.id
  tags = {
    Name               = "IT-Tools_IGW"
    Project            = var.project_tag
  }
}
# #Nat Gateway
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
# #Route Association
resource "aws_route_table_association" "associations" {
  for_each             = local.associations
  subnet_id            = each.value.subnet_id
  route_table_id       = each.value.route_table_id
}
#VPC Endpoints
resource "aws_security_group" "Endpoint_SG" {
  name                  = "Endpoint_SG"
  description           = "Allow traffic Fargate task to ECR repo"
  vpc_id               = aws_vpc.IT-Tools_VPC.id

  tags = {
    Name                = "Endpoint_SG"
    Project             = var.project_tag
  }
}
#Create Security group rule resources to avoid a cycle error
resource "aws_security_group_rule" "task_to_endpoint" {
  security_group_id        = var.ecs_sg.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Endpoint_SG.id
  depends_on = [ var.ecs_sg ]
}
resource "aws_security_group_rule" "task_to_s3" {
  security_group_id        = var.ecs_sg.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  prefix_list_ids          = [ var.prefix_list ]
  depends_on = [ var.ecs_sg ]
}
resource "aws_security_group_rule" "allow_from_task" {
  security_group_id        = aws_security_group.Endpoint_SG.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.ecs_sg.id
  depends_on = [ var.ecs_sg ]
}
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.IT-Tools_VPC.id
  service_name        = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.Endpoint_SG.id ]
  subnet_ids          = [ aws_subnet.Subnets["priv1"].id, aws_subnet.Subnets["priv2"].id ]
  private_dns_enabled = true

  tags = {
    Name              = "ecr_endpoint_api"
    Project           = var.project_tag
  }
}
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.IT-Tools_VPC.id
  service_name        = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.Endpoint_SG.id ]
  subnet_ids          = [ aws_subnet.Subnets["priv1"].id, aws_subnet.Subnets["priv2"].id ]
  private_dns_enabled = true

  tags = {
    Name              = "ecr_endpoint_dkr"
    Project           = var.project_tag
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.IT-Tools_VPC.id
  service_name      = "com.amazonaws.eu-west-2.s3"
  route_table_ids   = [ aws_route_table.Private_Route.id ]

  tags = {
    Name            = "s3_endpoint"
    Project         = var.project_tag
  }
}
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.IT-Tools_VPC.id
  service_name        = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids  = [ aws_security_group.Endpoint_SG.id ]
  subnet_ids          = [ aws_subnet.Subnets["priv1"].id, aws_subnet.Subnets["priv2"].id ]

  tags = {
    Name = "cloudwatch-logs-endpoint"
    Project           = var.project_tag
  }
}