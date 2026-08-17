#Security Group
resource "aws_security_group" "ECS_SG" {
  name                  = "ECS_SG"
  description           = "Allow inbound alb traffic to ecs tasks"
  vpc_id                = var.vpc_id

  ingress {
    description         = "allow HTTP traffic to task"
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    security_groups     = [ var.alb_sg ]
  }
    
    ingress {
    description         = "allow health check from alb"
    from_port           = var.container_port
    to_port             = var.container_port
    protocol            = "tcp"
    security_groups     = [ var.alb_sg ]
  }

  tags = {
    Name                = "ECS_SG"
    Project             = var.project_tag
  }
}
resource "aws_security_group" "Endpoint_SG" {
  name                  = "Endpoint_SG"
  description           = "Allow traffic Fargate task to ECR repo"
  vpc_id                = var.vpc_id

  tags = {
    Name                = "Endpoint_SG"
    Project             = var.project_tag
  }
}
#Create Security group rule resources to avoid a cycle error
resource "aws_security_group_rule" "task_to_endpoint" {
  security_group_id        = aws_security_group.ECS_SG.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Endpoint_SG.id
}
resource "aws_security_group_rule" "task_to_s3" {
  security_group_id        = aws_security_group.ECS_SG.id
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  prefix_list_ids          = [ var.prefix_list ]
}
resource "aws_security_group_rule" "allow_from_task" {
  security_group_id        = aws_security_group.Endpoint_SG.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ECS_SG.id
}
#VPC Endpoints
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.Endpoint_SG.id ]
  subnet_ids          = [ var.private_subnet_1, var.private_subnet_2 ]
  private_dns_enabled = true

  tags = {
    Name              = "ecr_endpoint_api"
    Project           = var.project_tag
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.Endpoint_SG.id ]
  subnet_ids          = [ var.private_subnet_1, var.private_subnet_2 ]
  private_dns_enabled = true

  tags = {
    Name              = "ecr_endpoint_dkr"
    Project           = var.project_tag
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.eu-west-2.s3"
  route_table_ids   = [ var.private_route ]

  tags = {
    Name            = "ecr_endpoint"
    Project         = var.project_tag
  }
}
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids  = [ aws_security_group.Endpoint_SG.id ]
  subnet_ids          = [ var.private_subnet_1, var.private_subnet_2 ]

  tags = {
    Name = "cloudwatch-logs-endpoint"
    Project           = var.project_tag
  }
}

#ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name                      = "IT-Tools-Cluster"
  
  tags = {
    Name            = "IT-Tools_Cluster"
    Project         = var.project_tag
  }
}
#Task Definitions
resource "aws_ecs_task_definition" "IT-Tools-TD" {
  family                    = "IT-Tools-TD"
  requires_compatibilities  = [ "FARGATE" ]
  network_mode              = "awsvpc"
  cpu                       = var.cpu
  memory                    = var.memory
  execution_role_arn = var.execution_role_arn
  container_definitions     = jsonencode([
  {
    name                    = "IT-Tools-Container"
    image                   = "${var.repo_url}:${var.latest_tag}"
    essential               = true
    portMappings            = [
      {
        containerPort       = var.container_port
        hostPort            = var.host_port
        protocol            = "tcp"
        appProtocol         = "http"
      }
    ]
    restartPolicy           =  {
      enabled               = true
      ignoredExitCodes      = [0]
      restartAttemptPeriod  = 60
      }
    logConfiguration        = {
      logDriver             = "awslogs"
      options: {
      awslogs-group         = var.log_group
      awslogs-region        = "eu-west-2"
      awslogs-stream-prefix = "ecs"
      }
    }
  }
])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

#ECS Service
resource "aws_ecs_service" "ecs_service" {
  name                      = "IT-Tools_cluster_service"
  cluster                   = aws_ecs_cluster.cluster.id
  network_configuration {
    subnets                 = [ var.private_subnet_1, var.private_subnet_2 ]
    security_groups         = [ aws_security_group.ECS_SG.id ]
  }
  task_definition           = aws_ecs_task_definition.IT-Tools-TD.arn
  launch_type               = "FARGATE"
  desired_count             = 2
  platform_version          = "1.4.0"
  load_balancer {
    container_name          = "IT-Tools-Container"
    container_port          = var.container_port
    target_group_arn        = var.target_group_arn
  }
  lifecycle {
    ignore_changes = [ task_definition ]
  }
}
