# GitHub Actionsで使用するIAMロール
#
# OpenID Connect Providerについては事前に作成済みとする
# https://github.com/biglobe-isp/terraform-base/discussions/487

module "app_deploy_iam_role" {
  source = "git@github.com:biglobe-isp/terraform-aws-github-actions-iam-role.git?ref=tags/v0.2.0"

  name           = "user-${local.repository_name}-gh-app-deploy"
  subject_values = ["repo:biglobe-isp/${local.repository_name}:*"]
  policy         = data.aws_iam_policy_document.app_deploy.json
}

data "aws_iam_policy_document" "app_deploy" {
  # ECRへイメージをプッシュ／タグのコピー
  # https://github.com/aws-actions/amazon-ecr-login#permissions
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:ListImages",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [data.aws_ecr_repository.app.arn]
  }

  # ECSサービスのアップデート
  # https://github.com/aws-actions/amazon-ecs-deploy-task-definition#permissions
  statement {
    effect = "Allow"

    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]

    resources = [
      data.aws_ecs_service.online.arn,
      data.aws_ecs_service.batch.arn,
    ]
  }

  # ECSタスクへIAMロールを渡す
  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      data.aws_iam_role.ecs_task.arn,
      data.aws_iam_role.ecs_task_execution.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_ecr_repository" "app" {
  name = local.app_ecr_repository_name
}

data "aws_ecs_service" "online" {
  cluster_arn  = data.aws_ecs_cluster.online.arn
  service_name = local.online_ecs_name
}

data "aws_ecs_service" "batch" {
  cluster_arn  = data.aws_ecs_cluster.batch.arn
  service_name = local.batch_ecs_name
}

data "aws_ecs_cluster" "online" {
  cluster_name = local.online_ecs_name
}

data "aws_ecs_cluster" "batch" {
  cluster_name = local.batch_ecs_name
}

data "aws_iam_role" "ecs_task" {
  name = "user-${local.component_name}-ecs-task"
}

data "aws_iam_role" "ecs_task_execution" {
  name = "user-${local.component_name}-ecs-task-execution"
}

locals {
  # オンラインECSサービス名
  online_ecs_name = "${local.component_name}-${local.online_component_type}"

  # バッチECSサービス名
  batch_ecs_name = "${local.component_name}-${local.batch_component_type}"

  # コンポーネントタイプ：オンライン
  online_component_type = "online"

  # コンポーネントタイプ：バッチ
  batch_component_type = "batch"
}
