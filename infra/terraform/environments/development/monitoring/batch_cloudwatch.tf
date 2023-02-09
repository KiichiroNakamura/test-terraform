# CloudWatch メトリクスフィルタ

### CPU 使用率（バッチ）
resource "aws_cloudwatch_metric_alarm" "ecs_batch_cpu_utilization_alarm" {
  alarm_name          = "ecs_batch_cpu_utilization_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "95.0"
  alarm_description   = "ecs online cpu utilization alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
  dimensions          = {
    ClusterName = "mobile-call-history-online"
    ServiceName = "mobile-call-history-online"
  }
}

### メモリ使用率（バッチ）
resource "aws_cloudwatch_metric_alarm" "ecs_batch_memory_utilization_alarm" {
  alarm_name          = "ecs_batch_memory_utilization_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80.0"
  alarm_description   = "ecs batch memory utilization alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
  dimensions          = {
    ClusterName = "mobile-call-history-batch"
    ServiceName = "mobile-call-history-batch"
  }
}


## ECS Fargate バッチ

resource "aws_cloudwatch_log_metric_filter" "batch_metric_filter" {
  name           = "mobile-call-history Batch Error"
  pattern        = "subject=MHIS02"
  log_group_name = data.aws_cloudwatch_log_group.batch_privileged.name

  metric_transformation {
    name      = "mobile-call-history Batch Error"
    namespace = "Batch Error"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "batch_gc_alarm_metric_filter" {
  name           = "Batch Full GC Count"
  pattern        = "Full GC"
  log_group_name = data.aws_cloudwatch_log_group.batch_privileged.name

  metric_transformation {
    name      = "Batch Full GC Count"
    namespace = "Batch Full GC Alarm"
    value     = "1"
  }
}


# CloudWatch アラーム
#
# アラーム名 ( alarm_name ) およびアラーム説明 ( alarm_description ) は下記ルールに従う必要がある
# https://www.biglobe.net/pages/viewpage.action?pageId=234488663#id-3.02.5.2.%E3%82%BB%E3%83%AB%E3%83%95%E6%A7%8B%E7%AF%89%E3%83%A2%E3%83%87%E3%83%AB%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E7%9B%A3%E8%A6%96%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6-%E7%9B%A3%E8%A6%96%E3%82%A2%E3%83%A9%E3%83%BC%E3%83%A0%E4%BD%9C%E6%88%90%E3%83%AB%E3%83%BC%E3%83%AB

## ECS Fargate バッチ

resource "aws_cloudwatch_metric_alarm" "batch_metric_alarm" {
  alarm_name  = "batch_error_alarm"
  metric_name = "mobile-call-history Batch Error"
  namespace   = "Batch Error"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  period            = "60"
  statistic         = "Sum"
  threshold         = "1"
  alarm_description = "batch_error_alarm"
  alarm_actions     = ["arn:aws:sns:ap-northeast-1:${local.account_id}:bgl-aws-alarm"]
}

resource "aws_cloudwatch_metric_alarm" "batch_fullgc_critical" {
  alarm_name  = "batch_fullgc_critical_alarm"
  metric_name = "Batch Full GC Count"
  namespace   = "Batch Full GC Alarm"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  period    = "3600"
  statistic = "Sum"
  threshold = "7"
  alarm_description = "batch fullgc critical alarm"
  alarm_actions = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "batch_fullgc_warning" {
  alarm_name  = "batch_fullgc_warning_alarm"
  metric_name = "Batch Full GC Count"
  namespace   = "Batch Full GC Alarm"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  period    = "3600"
  statistic = "Sum"
  threshold = "3"
  alarm_description = "batch fullgc warning alarm"
  alarm_actions = [aws_sns_topic.alarm.arn]
}


data "aws_cloudwatch_log_group" "batch_privileged" {
  name = "/ecs/${local.component_name}/batch/privileged"
}

