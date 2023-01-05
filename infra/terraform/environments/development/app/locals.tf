# ローカル変数を定義
#
# 複数のファイルから参照される変数や、Data-only Modules経由で取得する変数を定義する。
# 単一ファイルからのみ参照される変数は、このファイルへ記載する必要はなく、メンテナンスしやすい場所へ書くこと。

locals {
  # サブシステム名
  subsystem_name = replace("biglobe-mobile", "_", "-")

  # コンポーネント名
  component_name = replace("mobile-call-history", "_", "-")

  # アプリケーション用ECRリポジトリ名
  app_ecr_repository_name = "mobile-call-history-app"

  # Fluent Bitのイメージタグ
  #
  # Dockerイメージ自体は下記リポジトリで管理されている
  # https://github.com/biglobe-isp/isp-library-fluent-bit
  #
  # また最新のタグは下記ファイルに定義されている
  # https://github.com/biglobe-isp/isp-library-fluent-bit/blob/develop/infra/buildspec/app/buildspec-multiarch.yml
  fluent_bit_image_tag = "release-2.26.0-cloudwatch-1"

  # Fluent Bitのイメージ名
  fluent_bit_image_name = "${local.bo_aws_hub_ecr_repository_url}/aws-for-fluent-bit-custom"

  # コンポーネントタイプ：オンライン
  online_component_type = "online"

  # コンポーネントタイプ：バッチ
  batch_component_type = "batch"

  # リリース時に使用するDockerタグ
  image_tag = "releasing"

  # コンテナのポート番号
  container_port = 8080

  # ゾーン名
#  zone_name = "${local.subsystem_name}.${local.bows_fqdn}"
  zone_name = "biglobe-mobile.bilobe.co.jp"

  # ドメイン名
  # domain_name = "${local.component_name}.${local.zone_name}"
  domain_name = "mobile-call-history.${local.zone_name}"

  # ヘルスチェック対象のパス
  health_check_path = "/app/${local.subsystem_name}/${local.component_name}/monitoring/check"

  # Route53 Private Zone ID
  #bows_zone_id = data.aws_route53_zone.bows.zone_id
  bows_zone_id = "Z01284512QWT157EW2872"

  # KMSのカスタマーマスターキー
  default_kms_key_arn = data.aws_kms_key.default.arn
}

# BOWSプライベートホストゾーン
#
# BO-AWS-HUBとZone Associate済み。
# data "aws_route53_zone" "bows" {
#   name         = local.zone_name
#   private_zone = true
# }

# KMSのカスタマーマスターキー
data "aws_kms_key" "default" {
  key_id = "alias/default"
}

# BOWS情報参照モジュールから取得できるローカル変数
locals {
  bows_fqdn                     = module.data_bows.bows_fqdn
  online_bo_aws_hub_url         = module.data_bows.online_bo_aws_hub_url
  batch_bo_aws_hub_url          = module.data_bows.batch_bo_aws_hub_url
  bo_smtp_server_fqdn           = module.data_bows.bo_smtp_server_fqdn
  bo_smtp_server_port           = module.data_bows.bo_smtp_server_port
  bo_cap_sftp_fqdn              = module.data_bows.bo_cap_sftp_fqdn
  bo_aws_hub_ecr_repository_url = module.data_bows.bo_aws_hub_ecr_repository_url
  bo_aws_hub_security_group_id  = module.data_bows.bo_aws_hub_security_group_id
}

module "data_bows" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-bows.git?ref=tags/v0.3.0"
}

# ネットワーク情報参照モジュールから取得できるローカル変数
locals {
  # vpc_id             = module.data_network.vpc_id
  # private_subnet_ids = module.data_network.private_subnet_ids
  vpc_id             = "vpc-08f41e3bc330f3c06"
  private_subnet_ids = ["subnet-03b977c4080b04e84","subnet-01074fdd56f042478"]
}

# module "data_network" {
#   source = "git@github.com:biglobe-isp/terraform-aws-data-network.git?ref=tags/v0.2.0"

#   # account_specifier = "${local.service_id}-${local.short_env_name}"
#   account_specifier = "bsd3317-dev"
# }

# アカウント情報参照モジュールから取得できるローカル変数
locals {
  account_alias  = module.data_account.account_alias
  region         = module.data_account.region
  service_id     = module.data_account.service_id
  short_env_name = module.data_account.short_env_name
}

module "data_account" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-account.git?ref=tags/v0.2.0"
}
