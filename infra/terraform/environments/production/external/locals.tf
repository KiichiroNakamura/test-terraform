# ローカル変数を定義
#
# 複数のファイルから参照される変数や、Data-only Modules経由で取得する変数を定義する。
# 単一ファイルからのみ参照される変数は、このファイルへ記載する必要はなく、メンテナンスしやすい場所へ書くこと。

locals {
  # サブシステム名
  subsystem_name = replace("biglobe-mobile", "_", "-")

  # ゾーン名
  zone_name = "${local.subsystem_name}.${local.bows_fqdn}"
}

# BOWS情報参照モジュールから取得できるローカル変数
locals {
  bows_fqdn = module.data_bows.bows_fqdn
}

module "data_bows" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-bows.git?ref=tags/v0.3.0"
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
  account_alias  = module.data_account.account_alias
  service_id     = module.data_account.service_id
  short_env_name = module.data_account.short_env_name
}

module "data_account" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-account.git?ref=tags/v0.2.0"
}
