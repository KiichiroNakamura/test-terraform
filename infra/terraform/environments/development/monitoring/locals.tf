# ローカル変数を定義
#
# 複数のファイルから参照される変数や、Data-only Modules経由で取得する変数を定義する。
# 単一ファイルからのみ参照される変数は、このファイルへ記載する必要はなく、メンテナンスしやすい場所へ書くこと。

locals {

  # コンポーネント名
  component_name = replace("mobile-call-history", "_", "-")
 
  # コンポーネントタイプ：オンライン
  online_component_type = "online"

  # コンポーネントタイプ：バッチ
  batch_component_type = "batch"

   # Eメールアドレス
  email_address = "kiichiro@mxz.mesh.ne.jp"

  # efsネーム
  efs_creation_token = "biglobe-mobile-aws-efs"

 }


# アカウント情報参照モジュールから取得できるローカル変数
locals {
  account_alias  = module.data_account.account_alias
  account_id     = module.data_account.account_id
  region         = module.data_account.region
  service_id     = module.data_account.service_id
  short_env_name = module.data_account.short_env_name
}

module "data_account" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-account.git?ref=tags/v0.2.0"
}

# # efs
# locals {
#   filesystem_id = data.aws_efs_file_system.efs.efs_creation_token.id
# }
# data "aws_efs_file_system"  "efs"{
#   create_token  = "mobile-call-history-efs"

# }