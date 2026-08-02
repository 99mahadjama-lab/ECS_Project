#Security Group
resource "aws_security_group" "ALB_SG" {
  name                  = "ALB_SG"
  description           = "Allow inbound https traffic to the ALB"
  vpc_id                = var.vpc_id

  ingress {
    description         = "Inbound HTTPS"
    from_port           = 443
    to_port             = 443
    protocol            = "tcp"
    cidr_blocks         = ["0.0.0.0/0"]
  }

  ingress {
    description         = "allow ping from Dev"
    from_port           = -1
    to_port             = -1
    protocol            = "icmp"
    cidr_blocks         = [var.dev_ip]
  }

  egress {
    description         = "Outbound HTTP" 
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    cidr_blocks         = [var.private_subnet_1_CIDR , var.private_subnet_2_CIDR]

  }

  tags = {
    Name                = "ALB_SG"
    Project             = var.project_tag
  }
}

#Target Group
resource "aws_lb_target_group" "Target_Group" {
  name                  = "IT-Tools-TG"
  port                  = 80
  protocol              = "HTTP"
  vpc_id                = var.vpc_id
  target_type           = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Name                = "ALB-Target-Group"
    Project             = var.project_tag
  }
}

#ALB
resource "aws_lb" "IT-Tools_ALB" {
  name                  = "IT-Tools-ALB"
  load_balancer_type    = "application"
  ip_address_type       = "ipv4"
  subnets               = [var.public_subnet_1, var.public_subnet_2]
  security_groups       = [aws_security_group.ALB_SG.id]

  tags = {
    Name                = "IT-Tools-ALB"
    Project             = var.project_tag
  }
}

#ALB Listener
resource "aws_lb_listener" "front_end" {
  depends_on = [ var.cert_validated ]
  load_balancer_arn     = aws_lb.IT-Tools_ALB.arn
  port                  = "443"
  protocol              = "HTTPS"
  certificate_arn       = var.certificate_arn
  default_action {
    type                = "forward"
    target_group_arn    = aws_lb_target_group.Target_Group.arn
  } 
  tags = {
    Name                = "Front_End_Listener"
    Project             = var.project_tag
  }
}
#Direct traffic to ALB
resource "aws_route53_record" "alias" {
  zone_id = var.hosted_zone
  name    = "it-tools.${var.my_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.IT-Tools_ALB.dns_name
    zone_id                = aws_lb.IT-Tools_ALB.zone_id
    evaluate_target_health = true
  }
}