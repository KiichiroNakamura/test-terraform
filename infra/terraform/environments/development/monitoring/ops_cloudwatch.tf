### OPS-1
resource "aws_cloudwatch_metric_alarm" "instance_status_check_1" {
  alarm_name          = "instance_status_check_1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1.0"
  alarm_description   = "instance status check ops-1"
  alarm_actions       = [aws_sns_topic.alarm.arn]
  dimensions          = {
    Name              = "ops-${local.short_env_name}-1"
  }
}

### OPS-2
resource "aws_cloudwatch_metric_alarm" "instance_status_check_2" {
  alarm_name          = "instance_status_check_2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1.0"
  alarm_description   = "instance status check ops-2"
  alarm_actions       =[aws_sns_topic.alarm.arn]
  dimensions          = {
    Name              = "ops-${local.short_env_name}-2"
  }
}
