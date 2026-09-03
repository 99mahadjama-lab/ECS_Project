#create cloudwatch log group
resource "aws_cloudwatch_log_group" "IT-Tools-Logs" {
  name                      = "IT-Tools-Logs"

  tags = {
    Name                    = "IT-Tools-Logs"
    Project                 = var.project_tag
  }
}
#create cloudwatch alarms
resource "aws_cloudwatch_metric_alarm" "CPUUtilization" {
  alarm_description         = "This metric monitors cpu utilization"
  alarm_name                = "CPU_Alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 180
  statistic                 = "Average"
  threshold                 = 80

  tags = {
    Name                = "CPU_Alarm"
    Project             = var.project_tag
  }
}
resource "aws_cloudwatch_metric_alarm" "MemoryUtilization" {
  alarm_description         = "This metric monitors memory utilization"
  alarm_name                = "Memory-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ECS"
  period                    = 180
  statistic                 = "Average"
  threshold                 = 80
  
  tags = {
    Name                = "Memory_Alarm"
    Project             = var.project_tag
  }
}