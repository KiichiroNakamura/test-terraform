# RDS：Aurora
#
# リレーショナルデータベースは特殊な要件がない限りはAuroraを選択する。
# Auroraはクラウドに特化しており、パフォーマンスやスケーラビリティが有利なため。

module "aurora" {
  source = "git@github.com:biglobe-isp/terraform-aws-aurora-mysql.git?ref=tags/v0.3.1"

  identifier                   = local.component_name
  port                         = local.db_port
  engine_version               = local.engine_version
  instance_names               = local.instance_names
  instance_class               = local.instance_class
  performance_insights_enabled = local.performance_insights_enabled
  backup_retention_period      = local.backup_retention_period
  retention_in_days            = local.cloudwatch_logs_retention_in_days
  db_parameters                = local.db_parameters
  cluster_parameters           = local.cluster_parameters
  kms_key_id                   = local.default_kms_key_arn
  subnet_ids                   = local.private_subnet_ids
  vpc_security_group_ids       = [aws_security_group.aurora.id]
  deletion_protection          = false
  skip_final_snapshot          = true
}

locals {
  # DBパラメータグループのパラメータ
  db_parameters = []

  # RDSクラスタパラメータグループのパラメータ
  cluster_parameters = [
    # 文字コード
    { name = "character_set_client", value = local.db_character_set, apply_method = "immediate" },
    { name = "character_set_connection", value = local.db_character_set, apply_method = "immediate" },
    { name = "character_set_database", value = local.db_character_set, apply_method = "immediate" },
    { name = "character_set_results", value = local.db_character_set, apply_method = "immediate" },
    { name = "character_set_server", value = local.db_character_set, apply_method = "immediate" },

    # 照合順序
    { name = "collation_connection", value = local.db_collation, apply_method = "immediate" },
    { name = "collation_server", value = local.db_collation, apply_method = "immediate" },

    # タイムゾーン
    { name = "time_zone", value = "Asia/Tokyo", apply_method = "immediate" },

    # トランザクション分離レベル
    # https://kikai.hatenablog.jp/entry/20140212/1392171784
    { name = "transaction_isolation", value = "READ-COMMITTED", apply_method = "immediate" },

    # スロークエリログ（1:有効化、0:無効化）
    { name = "slow_query_log", value = "1", apply_method = "immediate" },

    # スロークエリログと判定する秒数
    { name = "long_query_time", value = "1", apply_method = "immediate" },
  ]

  # DBの文字コード
  db_character_set = "utf8"

  # DBの照合順序
  db_collation = "utf8_general_ci"
}

# データベースのセキュリティグループ
#
# IngressのセキュリティグループルールはECSと密結合なので、ECSと一緒に定義している。
# appディレクトリを確認すること。
resource "aws_security_group" "aurora" {
  name   = "${local.component_name}-aurora"
  vpc_id = local.vpc_id
  tags = {
    "Name" = "${local.component_name}-aurora"
  }

  lifecycle {
    # 別tfstateファイルで管理しているaws_security_group_ruleリソースの影響を受けないようにする
    ignore_changes = [ingress]
  }
}

resource "aws_security_group_rule" "aurora_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aurora.id
}
