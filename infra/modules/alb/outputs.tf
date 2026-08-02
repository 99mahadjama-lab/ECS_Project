output "target_group_arn" {
  value = aws_lb_target_group.Target_Group.arn
}
output "alb_dns_name" {
  value = aws_lb.IT-Tools_ALB.dns_name
}
output "alb_zone_id" {
  value = aws_lb.IT-Tools_ALB.zone_id 
}
output "subdomain" {
  value = aws_route53_record.alias.name
}
output "alb_sg" {
  value = aws_security_group.ALB_SG.id
}