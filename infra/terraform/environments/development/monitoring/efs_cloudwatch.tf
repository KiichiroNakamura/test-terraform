### 汎用パフォーマンスモードIO
resource "aws_cloudwatch_metric_alarm" "percent_io_limit" {
  alarm_name          = "percent_io_limit"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "PercentIOLimit"
  namespace           = "AWS/EFS"
  period              = "3600"
  statistic           = "Average"
  threshold           = "80.0"
  alarm_description   = "rds cpu utilization alarm"
  alarm_actions       = [aws_sns_topic.alarm.arn]
}


resource "aws_cloudwatch_metric_alarm" "bandwidth_utilization" {
  alarm_name          = "bandwidth_utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 70
  treat_missing_data  = "missing"
  datapoints_to_alarm = 1
  actions_enabled     = "true"
#   alarm_actions       = ["sns topic arn"]
#   ok_actions          = ["sns topic arn"]

  # 
  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/EFS"
      metric_name = "PermittedThroughput"
      period      = 300
      stat        = "Average"

      dimensions = {
        instanceID = "instance id"
      }
    }
  }

  # 
  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/FES"
      metric_name = "TotalIOBytes"
      period      = 300
      stat        = "Average"

      dimensions = {
        DBInstanceIdentifier = "instance id"
      }
    }
  }

  # 計算式用metric_query
  metric_query {
    id          = "e2"
    # return_data = true
    expression  = "(m2/1048576)"
    label       = "Throughput MiB/second"
  }

 # 計算式用metric_query
  metric_query {
    id          = "e1"
    # return_data = true
    expression  = "(m1/1048576)/(300)"
    label       = "Total IO MiB/second"
  }

 # 計算式用metric_query
  metric_query {
    id          = "e3"
    return_data = true
    expression  = "(e1*e2/100)"
    label       = "Throughput utilization(%)"
  }

}