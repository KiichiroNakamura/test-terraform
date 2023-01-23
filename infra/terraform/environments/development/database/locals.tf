# ローカル変数を定義
#
# 複数のファイルから参照される変数や、Data-only Modules経由で取得する変数を定義する。
# 単一ファイルからのみ参照される変数は、このファイルへ記載する必要はなく、メンテナンスしやすい場所へ書くこと。

locals {
  # サブシステム名
  subsystem_name = replace("biglobe-mobile", "_", "-")

  # コンポーネント名
  component_name = replace("mobile-call-history", "_", "-")

  # DBのポート番号
  db_port = 3306

  # 最新のエンジンバージョンは英語版ドキュメントを確認すること
  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Updates.Versions.html
  major_version  = "8.0"
  aurora_version = "3.02.1"
  engine_version = "${local.major_version}.mysql_aurora.${local.aurora_version}"

  # データベース名
  db_database = "mobile-call-history"

  # データベース接続ユーザ名
  db_username = "mobile-call-history"

  # Masterのホスト名
  master_host_name = "master.${aws_route53_zone.db_private.name}"

  # Readレプリカのホスト名
  readonly_host_name = "readonly.${aws_route53_zone.db_private.name}"

  # KMSのカスタマーマスターキー
  default_kms_key_arn = data.aws_kms_key.default.arn
}

data "aws_kms_key" "default" {
  key_id = "alias/default"
}

# ネットワーク情報参照モジュールから取得できるローカル変数
locals {
  # vpc_id             = module.data_network.vpc_id
  # private_subnet_ids = module.data_network.private_subnet_ids
  vpc_id             = "vpc-09664fe7394151f99"
  private_subnet_ids = ["subnet-0c2679ae97687129d","subnet-0fd0c374d8d3841ff"]
}

# module "data_network" {
#   source = "git@github.com:biglobe-isp/terraform-aws-data-network.git?ref=tags/v0.2.0"

#   account_specifier = "${local.service_id}-${local.short_env_name}"
# }

# アカウント情報参照モジュールから取得できるローカル変数
locals {
  # service_id     = module.data_account.service_id
  # short_env_name = module.data_account.short_env_name
  service_id     = "bsd9999-dev"
  short_env_name = "dev"
}

# module "data_account" {
#   source = "git@github.com:biglobe-isp/terraform-aws-data-account.git?ref=tags/v0.2.0"
# }
