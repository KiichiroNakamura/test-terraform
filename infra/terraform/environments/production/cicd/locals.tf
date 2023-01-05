# ローカル変数を定義
#
# 複数のファイルから参照される変数や、Data-only Modules経由で取得する変数を定義する。
# 単一ファイルからのみ参照される変数は、このファイルへ記載する必要はなく、メンテナンスしやすい場所へ書くこと。

locals {
  # コンポーネント名
  component_name = replace("mobile-call-history", "_", "-")

  # アプリケーション用ECRリポジトリ名
  app_ecr_repository_name = "mobile-call-history-app"

  # データベースマイグレーション用ECRリポジトリ名
  db_migration_ecr_repository_name = "mobile-call-history-db-migration"

  # GitHubのリポジトリ名
  repository_name = "biglobe-mobile-aws-infra"

  # KMSのカスタマーマスターキー
  default_kms_key_arn = data.aws_kms_key.default.arn

  # コンポーネントタイプ：データベースマイグレーション
  db_migration_component_type = "db-migration"

  # データベースマイグレーション用Dockerタグ
  db_migration_tag_prefix_list = ["latest"]
}

# KMSのカスタマーマスターキー
data "aws_kms_key" "default" {
  key_id = "alias/default"
}

# ネットワーク情報参照モジュールから取得できるローカル変数
locals {
  vpc_id = module.data_network.vpc_id
}

module "data_network" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-network.git?ref=tags/v0.2.0"

  account_specifier = "${local.service_id}-${local.short_env_name}"
}

# アカウント情報参照モジュールから取得できるローカル変数
locals {
  account_id     = module.data_account.account_id
  region         = module.data_account.region
  service_id     = module.data_account.service_id
  short_env_name = module.data_account.short_env_name
}

module "data_account" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-account.git?ref=tags/v0.2.0"
}
