# CloudWatch メトリクスフィルタ
### ロードアベレージ
resource "aws_cloudwatch_log_metric_filter" "aurora_load_avarage_metric_filter_alpha" {
  name           = "aurora-load-avarege-alpha"
  pattern        = "{ $.instanceID = ${local.component_name}-alpha }"

  # + "{ \"-alpha\" }"

  log_group_name = "RDSOSMetrics"

  metric_transformation {
    name      = "aurora-load-avarege-alpha"
    namespace = "RDSOSMetrics"
    value     = "$.loadAverageMinute.five"
  }
}

resource "aws_cloudwatch_log_metric_filter" "aurora_load_avarage_metric_filter_bravo" {
  name           = "aurora-load-avarege-0"
  pattern        = "{ $.instanceID = data.aws_db_instance.mobile_call_history_bravo }"
  log_group_name = "RDSOSMetrics"

  metric_transformation {
    name      = "aurora-load-avarege-bravo"
    namespace = "RDSOSMetrics"
    value     = "$.loadAverageMinute.five"
  }
}

# CloudWatch アラーム
## ロードアベレージ
resource "aws_cloudwatch_metric_alarm" "aurora_load_avarage_alarm_0" {
  alarm_name          = "aurora_load_avarage_alarm_0"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.aurora_load_avarage_metric_filter_alpha.metric_transformation[0].name
  namespace           = "RDSOSMetrics"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "rds instance 0 load average alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "aurora_load_avarage_alarm_1" {
  alarm_name          = "aurora_load_avarage_alarm_1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.aurora_load_avarage_metric_filter_bravo.metric_transformation[0].name
  namespace           = "RDSOSMetrics"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "rds instance 1 load average alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
}

### rds レプリカラグ
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  alarm_name          = "rds_replica_lag_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AuroraReplicaLag"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10000"
  alarm_description   = "rds replica lag alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
}

### rds cpu 使用率
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_critical" {
  alarm_name          = "rds_cpu_utilization_critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "600"
  statistic           = "Average"
  threshold           = "95.0"
  alarm_description   = "rds cpu utilization critical"
  alarm_actions       = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization_alarm" {
  alarm_name          = "rds_cpu_utilization_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "600"
  statistic           = "Average"
  threshold           = "55.0"
  alarm_description   = "rds cpu utilization alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
}

data "aws_db_instance" "mobile_call_history_alpha" {
  db_instance_identifier = "mobile-call-history-alpha"
}

data "aws_db_instance" "mobile_call_history_bravo" {
  db_instance_identifier = "mobile-call-history-bravo"
}
