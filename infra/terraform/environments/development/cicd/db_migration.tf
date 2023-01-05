# データベースマイグレーション
#
# GitHub Actionsから実行するECSタスクと
# GitHub Actionsで使用するIAMロール

# ECSタスク
resource "aws_ecs_task_definition" "db_migration" {
  family                   = "${local.component_name}-${local.db_migration_component_type}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn

  # 分かりづらいが「1vCPU=1024」である
  cpu = 256

  # CPUのサイズに応じて、設定可能なメモリの指定も変わる
  # Fargateの場合、CPUとメモリで定義できる値の組み合わせが決まっているので注意
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
  memory = 512

  # コンテナ定義
  container_definitions = jsonencode([
    {
      name        = local.db_migration_ecr_repository_name
      image       = "${aws_ecr_repository.db_migration.repository_url}:latest"
      secrets     = local.datasource_secrets # TODO 要確認
      environment = []
      essential   = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.db_migration.name
          awslogs-region        = local.region
          awslogs-stream-prefix = local.db_migration_component_type
        }
      }

      # forces replacementを抑制する
      # 下記の記述がないとapplyのたびにECSタスクが作り直されてしまうのでワークアラウンドとして記述しておく
      cpu         = 0
      mountPoints = []
      volumesFrom = []
    }
  ])
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "db_migration" {
  name              = "/ecs/${local.component_name}/${local.db_migration_component_type}"
  retention_in_days = local.cloudwatch_logs_retention_in_days
  kms_key_id        = local.default_kms_key_arn
}

# ECSクラスタ
resource "aws_ecs_cluster" "db_migration" {
  name = "${local.component_name}-${local.db_migration_component_type}"

  # メトリクス収集ができるようCloudWatch Container Insightsを有効にする
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/cloudwatch-container-insights.html
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# セキュリティグループ
resource "aws_security_group" "db_migration" {
  name   = "${local.component_name}-${local.db_migration_component_type}"
  vpc_id = local.vpc_id

  tags = {
    "Name" = "${local.component_name}-${local.db_migration_component_type}"
  }
}

resource "aws_security_group_rule" "db_migration_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_migration.id
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_migration.id
  security_group_id        = data.aws_security_group.default_vpc_endpoint.id
}

resource "aws_security_group_rule" "aurora_ingress" {
  type                     = "ingress"
  from_port                = data.aws_ssm_parameter.datasource_port.value
  to_port                  = data.aws_ssm_parameter.datasource_port.value
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_migration.id
  security_group_id        = data.aws_security_group.aurora.id
}

data "aws_security_group" "default_vpc_endpoint" {
  name   = "default-vpc-endpoint"
  vpc_id = local.vpc_id
}

data "aws_security_group" "aurora" {
  name = "${local.component_name}-aurora"
}

# ECRリポジトリ
resource "aws_ecr_repository" "db_migration" {
  name = local.db_migration_ecr_repository_name

  # イメージタグを変更可能にするかどうか指定する
  # IMMUTABLEを指定すると、イメージタグを上書きできなくなる
  image_tag_mutability = "MUTABLE"

  # プッシュ時にセキュリティスキャンを実行する
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECRライフサイクルポリシー
#
# リポジトリごとに保存できるイメージ数は10,000という制約があるので
# 不要なイメージを自動削除できるようにする
resource "aws_ecr_lifecycle_policy" "db_migration" {
  repository = aws_ecr_repository.db_migration.name

  policy = jsonencode({
    rules = [
      {
        # 指定したタグの最新のイメージ1個は削除しない
        rulePriority = 1
        description  = "Keep [${join(", ", local.db_migration_tag_prefix_list)}] tagged latest image, never delete"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = local.db_migration_tag_prefix_list
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        # タグの有無に関わらず最新のイメージ30個を保持する
        rulePriority = 2
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# GitHub Actionsのデータベースマイグレーションで使用するIAMロール
#
# OpenID Connect Providerについては事前に作成済みとする

module "db_migration_iam_role" {
  source = "git@github.com:biglobe-isp/terraform-aws-github-actions-iam-role.git?ref=tags/v0.2.0"

  name           = "user-${local.repository_name}-gh-db-migration"
  subject_values = ["repo:biglobe-isp/${local.repository_name}:*"]
  policy         = data.aws_iam_policy_document.db_migration.json
}

data "aws_iam_policy_document" "db_migration" {
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

    resources = [aws_ecr_repository.db_migration.arn]
  }

  # ECSタスクの実行
  statement {
    effect = "Allow"

    actions = [
      "ecs:ListTaskDefinitions",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:RunTask",
    ]

    resources = [
      "arn:aws:ecs:${local.region}:${local.account_id}:task-definition/${aws_ecs_task_definition.db_migration.family}:*",
    ]
  }

  # ネットワークリソースの参照
  statement {
    effect = "Allow"

    actions = [
      "iam:ListAccountAliases",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
    ]

    resources = ["*"]
  }

  # ECSタスクへIAMロールを渡す
  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      data.aws_iam_role.ecs_task_execution.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

locals {
  # データベース接続に必要な環境変数をParameter StoreやSecrets Managerから注入する
  datasource_secrets = [
    {
      name      = "DB_HOST"
      valueFrom = data.aws_ssm_parameter.datasource_host.name
    },
    {
      name      = "DB_PORT"
      valueFrom = data.aws_ssm_parameter.datasource_port.name
    },
    {
      name      = "DB_DATABASE"
      valueFrom = data.aws_ssm_parameter.datasource_database.name
    },
    {
      name      = "DB_USERNAME"
      valueFrom = data.aws_ssm_parameter.datasource_username.name
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = data.aws_secretsmanager_secret.datasource_password.arn
    },
  ]
}

# Parameter Store
data "aws_ssm_parameter" "datasource_host" {
  name = "/${local.component_name}/datasource/host"
}

data "aws_ssm_parameter" "datasource_port" {
  name = "/${local.component_name}/datasource/port"
}

data "aws_ssm_parameter" "datasource_database" {
  name = "/${local.component_name}/datasource/database"
}

data "aws_ssm_parameter" "datasource_username" {
  name = "/${local.component_name}/datasource/username"
}

# Secrets Manager
data "aws_secretsmanager_secret" "datasource_password" {
  name = "/${local.component_name}/datasource/password"
}
