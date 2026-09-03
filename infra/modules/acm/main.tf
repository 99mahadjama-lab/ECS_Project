#Create Hosted Zone
data "aws_route53_zone" "primary" {
  name = var.my_domain
}
#Update DNS Record for domain
resource "aws_route53domains_registered_domain" "my_domain" {
  domain_name = var.my_domain
  provider    = aws.us_east_1

  dynamic "name_server" {
    for_each = data.aws_route53_zone.primary.name_servers
    content {
      name = name_server.value
    }
  }
  
  tags = {
    Name                = "IT-Tools-Domain"
    Project             = var.project_tag
  }
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
#Create ACM Cert
resource "aws_acm_certificate" "cert" {
  domain_name       = var.subdomain
  validation_method = "DNS"

  tags = {
    Name                = "ACM_Cert"
    Project             = var.project_tag
  }

  lifecycle {
    create_before_destroy = true
  }
}
#ACM Validation
resource "aws_route53_record" "cert_validate" {
  depends_on = [ aws_acm_certificate.cert ]
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.id
}
resource "aws_acm_certificate_validation" "cert_valid" {
    certificate_arn   = aws_acm_certificate.cert.arn
}
 