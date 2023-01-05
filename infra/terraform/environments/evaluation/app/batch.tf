# ECS：バッチ
#
# ECS関連のリソースだけでなく、ALBとの連携部分も一緒に定義する。

locals {
  # バッチECSサービス名
  batch_ecs_name = "${local.component_name}-${local.batch_component_type}"
}

# ECSサービス
module "batch_ecs_service" {
  source = "git@github.com:biglobe-isp/terraform-aws-ecs-service.git?ref=tags/v0.3.0"

  # オンライン／バッチ固有部分
  name             = local.batch_ecs_name
  target_group_arn = aws_lb_target_group.batch.id
  desired_count    = local.desired_count

  # オンライン／バッチ共通部分
  container_name     = local.app_ecr_repository_name
  container_port     = local.container_port
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.ecs.id]
  execution_role_arn = module.ecs_task_execution_iam_role.arn
  task_role_arn      = module.ecs_task_iam_role.arn

  # コンテナ定義
  container_definitions = jsonencode([
    {
      name              = local.app_ecr_repository_name
      image             = "${aws_ecr_repository.app.repository_url}:${local.image_tag}"
      secrets           = concat(local.datasource_secrets, local.ssh_secrets)
      environment       = concat(local.environment, local.batch_environment)
      essential         = true
      memoryReservation = 896
      portMappings      = local.port_mappings

      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name              = "cloudwatch_logs"
          region            = local.region
          log_group_name    = module.batch_bows_cloudwatch_logs.privileged_name
          log_stream_prefix = "${local.batch_component_type}-"
        }
      }

      # forces replacementを抑制する
      # 下記の記述がないとapplyのたびにECSタスクが作り直されてしまうのでワークアラウンドとして記述しておく
      cpu         = 0
      mountPoints = []
      volumesFrom = []
    },
    {
      name                  = "log_router"
      image                 = local.fluent_bit_image
      environment           = concat(local.fluentbit_environment, local.batch_fluentbit_environment)
      essential             = true
      memoryReservation     = local.fluentbit_memory_reservation
      firelensConfiguration = local.firelens_configuration

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.batch_bows_cloudwatch_logs.log_router_name
          awslogs-region        = local.region
          awslogs-stream-prefix = local.batch_component_type
        }
      }

      # forces replacementを抑制する
      # 下記の記述がないとapplyのたびにECSタスクが作り直されてしまうのでワークアラウンドとして記述しておく
      cpu          = 0
      mountPoints  = []
      volumesFrom  = []
      portMappings = []
      user         = "0"
    }
  ])
}

# CloudWatch Logs
module "batch_bows_cloudwatch_logs" {
  source = "git@github.com:biglobe-isp/terraform-aws-bows-cloudwatch-logs.git?ref=tags/v0.2.0"

  # オンライン／バッチ固有部分
  name_prefix = "/ecs/${local.component_name}/${local.batch_component_type}"

  # オンライン／バッチ共通部分
  retention_in_days = local.cloudwatch_logs_retention_in_days
  kms_key_id        = local.default_kms_key_arn
}

# ECS用のALBリスナールール
resource "aws_lb_listener_rule" "batch" {
  listener_arn = module.alb.listener_arn

  # リスナールールは複数定義できるため、優先順位を定義する
  # 省略すると勝手に割り振られてコントロールしづらいため明示的に指定しておく
  # 数字が小さいほど、優先順位が高い
  priority = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.batch.arn
  }

  condition {
    host_header {
      values = [aws_route53_record.batch.fqdn]
    }
  }
}

# ECS用のターゲットグループ
resource "aws_lb_target_group" "batch" {
  name     = local.batch_ecs_name
  port     = local.container_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  # Fargateでは必ずipにする必要がある
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/service-load-balancing.html
  target_type = "ip"

  # ターゲットを登録解除する前にALBが待機する時間を秒単位で指定
  # デフォルト値は300秒
  deregistration_delay = 300

  health_check {
    # ヘルスチェックで使用するパス
    # アプリケーション側で実装する必要がある
    path = local.health_check_path

    # 正常判定を行うまでのヘルスチェック実行回数
    healthy_threshold = 5

    # 異常判定を行うまでのヘルスチェック実行回数
    unhealthy_threshold = 2

    # ヘルスチェックのタイムアウト時間（秒）
    timeout = 5

    # ヘルスチェックの実行間隔（秒）
    interval = 30

    # 正常判定を行うために使用するHTTPステータスコード
    matcher = 200

    # ヘルスチェックで使用するポート
    # traffic-portを指定した場合、portで指定したポートを使用する
    port = "traffic-port"

    # ヘルスチェック時に使用するプロトコル
    protocol = "HTTP"
  }

  # これがないとaws_lb・aws_lb_target_group・aws_ecs_serviceの3つのリソースを同時にapplyするとエラーになる。
  # それを回避するためのワークアラウンドとして、依存関係を明示的に記述。
  # https://github.com/biglobe-isp/Freyja/issues/1039
  depends_on = [module.alb]
}

# ECS用のALIASレコード
resource "aws_route53_record" "batch" {
  zone_id = local.bows_zone_id
  name    = "${local.batch_component_type}.${local.domain_name}"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}
