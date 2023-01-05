# IAMロール
#
# ECSが使用するIAMロールを2つ定義する。
#
# - ECSタスクIAMロール：コンテナ自体に権限を付与する
# - ECSタスク実行IAMロール：コンテナデプロイ時に必要な権限を付与する
#
# ややこしいが両方必要。
# アプリケーションがS3へアクセスするなど、AWS APIを使用する場合は
# ECSタスクIAMロールに対して権限を付与すればよい。

# ECSタスクIAMロール
module "ecs_task_iam_role" {
  source = "git@github.com:biglobe-isp/terraform-aws-iam-role.git?ref=tags/v0.2.0"

  name       = "user-${local.component_name}-ecs-task"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task.json
}

data "aws_iam_policy_document" "ecs_task" {
  # firelensからCloudWatch Logsへ書き込むために必要
  # https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  # Micrometerが収集したJVMメトリクスをCloudWatchへ送るために必要
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
}

# ECSタスク実行IAMロール
module "ecs_task_execution_iam_role" {
  source = "git@github.com:biglobe-isp/terraform-aws-iam-role.git?ref=tags/v0.2.0"

  name       = "user-${local.component_name}-ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

data "aws_iam_policy_document" "ecs_task_execution" {
  # SSMパラメータストアから環境変数を注入するために必要
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = ["*"]
  }

  # Secrets Managerから環境変数を注入するために必要
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }

  # 暗号化された値を復号するために必要
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}

# AWS管理のサービスロールの権限を追加
#
# ECRの参照とCloudWatch Logsへの書き込み権限が付与される
# https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_execution_IAM_role.html
resource "aws_iam_role_policy_attachment" "additional_ecs_task_execution" {
  role       = module.ecs_task_execution_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
