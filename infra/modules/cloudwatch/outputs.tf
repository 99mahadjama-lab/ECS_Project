output "CPUUtilization" {
  value = aws_cloudwatch_metric_alarm.CPUUtilization.alarm_name
}
output "MemoryUtilization" {
  value = aws_cloudwatch_metric_alarm.MemoryUtilization.alarm_name
}
output "log_group" {
  value = aws_cloudwatch_log_group.IT-Tools-Logs
}