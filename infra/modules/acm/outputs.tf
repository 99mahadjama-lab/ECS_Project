output "Hosted_Zone" {
  value = data.aws_route53_zone.primary
}
output "Subdomain" {
  value = aws_acm_certificate.cert.domain_name
}
output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}
output "cert_validated" {
  value = aws_acm_certificate_validation.cert_valid
}