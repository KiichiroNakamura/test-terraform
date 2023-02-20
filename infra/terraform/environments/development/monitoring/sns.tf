# SNSトピック: 通話明細アラーム（サービス担当）
resource "aws_sns_topic" "alarm" {
  name            = "user-${local.component_name}-alarm"
  display_name    = "通話明細アラーム（サービス担当）"
  delivery_policy = <<DELIVERY_POLICY
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "numRetries": 3,
      "numNoDelayRetries": 0,
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numMinDelayRetries": 0,
      "numMaxDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false
  }
}
DELIVERY_POLICY
}

# 通話明細アラームトピックとIAMポリシー関連付け
resource "aws_sns_topic_policy" "alarm_topic" {
  arn    = aws_sns_topic.alarm.arn
  policy = data.aws_iam_policy_document.alarm_topic.json
}

# 通話明細アラームトピック IAMポリシー
data "aws_iam_policy_document" "alarm_topic" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    resources = [aws_sns_topic.alarm.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        local.account_id,
      ]
    }
  }
}

# SNSサブスクリプション: Eメール
resource "aws_sns_topic_subscription" "email" {
  topic_arn      = aws_sns_topic.alarm.arn
  protocol       = "email"
  endpoint       = local.email_address
  redrive_policy = <<REDRIVE_POLICY
{
  "deadLetterTargetArn": "${aws_sqs_queue.alarm_dead_letter.arn}"
}
REDRIVE_POLICY
}

# デッドレターキュー
resource "aws_sqs_queue" "alarm_dead_letter" {
  name       = "dead-user-aws-alarm"
  fifo_queue = false
}

# デッドレターキューとIAMポリシー関連付け
resource "aws_sqs_queue_policy" "alarm_dead_letter" {
  queue_url = aws_sqs_queue.alarm_dead_letter.id
  policy    = data.aws_iam_policy_document.alarm_dead_letter_queue.json
}

# デッドレターキュー IAMポリシー
data "aws_iam_policy_document" "alarm_dead_letter_queue" {
  statement {
    sid    = "__owner_statement"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions = [
      "SQS:*",
    ]
    resources = [aws_sqs_queue.alarm_dead_letter.arn]
  }

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions = [
      "sqs:SendMessage",
    ]
    resources = [aws_sqs_queue.alarm_dead_letter.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_sns_topic.alarm.arn,
      ]
    }
  }
}


