# ローカル変数を定義
#
# 複数のファイルから参照される変数や、Data-only Modules経由で取得する変数を定義する。
# 単一ファイルからのみ参照される変数は、このファイルへ記載する必要はなく、メンテナンスしやすい場所へ書くこと。

# ネットワーク情報参照モジュールから取得できるローカル変数
locals {
  # vpc_id             = module.data_network.vpc_id
  # private_subnet_ids = module.data_network.private_subnet_ids
  vpc_id             = "vpc-09664fe7394151f99"
  private_subnet_ids = ["subnet-0c2679ae97687129d","subnet-0fd0c374d8d3841ff"]
}

# module "data_network" {
#    source = "git@github.com:biglobe-isp/terraform-aws-data-network.git?ref=tags/v0.2.0"

# #   #account_specifier = "${local.service_id}-${local.short_env_name}"
#    account_specifier = "bsd3317-dev"
# }

# アカウント情報参照モジュールから取得できるローカル変数
locals {
  # account_id     = module.data_account.account_id
  # account_alias  = module.data_account.account_alias
  # region         = module.data_account.region
  # service_id     = module.data_account.service_id
  # short_env_name = module.data_account.short_env_name
  account_id     = module.data_account.account_id
  account_alias  = module.data_account.account_alias
  region         = module.data_account.region
  service_id     = module.data_account.service_id
  short_env_name = module.data_account.short_env_name
}

module "data_account" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-account.git?ref=tags/v0.2.0"
}
