# CloudWatch メトリクスフィルタ

resource "aws_cloudwatch_log_metric_filter" "online_metric_filter" {
  name           = "mobile-call-history API Error"
  pattern        = "MHIS02"
  log_group_name = data.aws_cloudwatch_log_group.online_privileged.name

  metric_transformation {
    name      = "mobile-call-history API Error"
    namespace = "API Error"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "online_gc_alarm_metric_filter" {
  name           = "Online Full GC Count"
  pattern        = "Full GC"
  log_group_name = data.aws_cloudwatch_log_group.online_privileged.name

  metric_transformation {
    name      = "Online Full GC Count"
    namespace = "Online Full GC Alarm"
    value     = "1"
  }
}

# CloudWatch アラーム
## ECS Fargate オンライン
resource "aws_cloudwatch_metric_alarm" "online_metric_alarm" {
  alarm_name  = "online_api_error_alarm"
  metric_name = "mobile-call-history API Error"
  namespace   = "API Error"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  period            = "60"
  statistic         = "Sum"
  threshold         = "1"
  alarm_description = "online_api_error_alarm"
  alarm_actions     = ["arn:aws:sns:ap-northeast-1:${local.account_id}:bgl-aws-alarm"]
}

resource "aws_cloudwatch_metric_alarm" "online_fullgc_critical" {
  alarm_name  = "online_fullgc_critical_alarm"
  metric_name = "Online Full GC Count"
  namespace   = "Online Full GC Alarm"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  period    = "3600"
  statistic = "Sum"
  threshold = "7"
  alarm_description = "online fullgc critical alarm"
  alarm_actions = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "online_fullgc_warning" {
  alarm_name  = "online_fullgc_warning_alarm"
  metric_name = "Online Full GC Count"
  namespace   = "Online Full GC Alarm"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"

  period    = "3600"
  statistic = "Sum"
  threshold = "3"
  alarm_description = "online fullgc warning alarm"
  alarm_actions = [aws_sns_topic.alarm.arn]
}

### メモリ使用率（オンライン）
resource "aws_cloudwatch_metric_alarm" "ecs_online_memory_utilization_alarm" {
  alarm_name          = "ecs_online_memory_utilization_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80.0"
  alarm_description   = "ecs online memory utilization alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
  dimensions          = {
    ClusterName = "${local.component_name}-${local.online_component_type}"
    ServiceName = "${local.component_name}-${local.online_component_type}"
  }
}

### CPU 使用率（オンライン）
resource "aws_cloudwatch_metric_alarm" "ecs_online_cpu_utilization_alarm" {
  alarm_name          = "ecs_online_cpu_utilization_alarm"
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
    ClusterName = "${local.component_name}-${local.online_component_type}"
    ServiceName = "${local.component_name}-${local.online_component_type}"
  }
}

data "aws_cloudwatch_log_group" "online_privileged" {
  name = "/ecs/${local.component_name}/online/privileged"
}


# CloudWatch メトリクスフィルタ

resource "aws_cloudwatch_log_metric_filter" "batch_metric_filter" {
  name           = "mobile-call-history Batch Error"
  pattern        = "MHIS02"
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
    ClusterName = "${local.component_name}-${local.batch_component_type}"
    ServiceName = "${local.component_name}-${local.batch_component_type}"
  }
}

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
    ClusterName = "${local.component_name}-${local.batch_component_type}"
    ServiceName = "${local.component_name}-${local.batch_component_type}"
  }
}

data "aws_cloudwatch_log_group" "batch_privileged" {
  name = "/ecs/${local.component_name}/batch/privileged"
}
