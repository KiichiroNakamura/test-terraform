# Parameter StoreとSecrets Manager
#
# データベースの設定情報を定義する。
# ここで定義した値はパラメータストアやSecrets Manager経由でECSなどへ渡す。
# Parameter StoreとSecrets Managerの使い分けは次のとおり。
#
# - Parameter Store：暗号化不要な設定情報を、値も含めて定義する
# - Secrets Manager：暗号化が必須なパスワードなどの秘匿情報を定義する／値自体はTerraformで管理しない
#
# Secrets Managerのリソースを作成した場合、別途AWSマネジメントコンソールから
# 管理対象の秘匿情報を手動で登録する必要がある。

# Parameter Store
#
# 暗号化不要な設定情報のみ定義すること。
# ここで定義した値はtfstateファイルに平文で書き込まれるため、パスワードやトークンなどは含めてはいけない
resource "aws_ssm_parameter" "datasource_url" {
  type        = "String"
  name        = "/${local.component_name}/datasource/url"
  value       = "jdbc:mysql://${local.master_host_name}:${local.db_port}/${local.db_database}"
  description = "データベース接続URL"
}

resource "aws_ssm_parameter" "datasource_readonly_url" {
  type        = "String"
  name        = "/${local.component_name}/datasource/readonly_url"
  value       = "jdbc:mysql://${local.readonly_host_name}:${local.db_port}/${local.db_database}"
  description = "データベース接続URL(ReadOnly)"
}

resource "aws_ssm_parameter" "datasource_host" {
  type        = "String"
  name        = "/${local.component_name}/datasource/host"
  value       = local.master_host_name
  description = "データベース接続ホスト"
}

resource "aws_ssm_parameter" "datasource_readonly_host" {
  type        = "String"
  name        = "/${local.component_name}/datasource/readonly_host"
  value       = local.readonly_host_name
  description = "データベース接続ホスト(ReadOnly)"
}

resource "aws_ssm_parameter" "datasource_database" {
  type        = "String"
  name        = "/${local.component_name}/datasource/database"
  value       = local.db_database
  description = "データベース名"
}

resource "aws_ssm_parameter" "datasource_username" {
  type        = "String"
  name        = "/${local.component_name}/datasource/username"
  value       = local.db_username
  description = "データベース接続ユーザー"
}

resource "aws_ssm_parameter" "datasource_port" {
  type        = "String"
  name        = "/${local.component_name}/datasource/port"
  value       = local.db_port
  description = "データベース接続ポート"
}

resource "aws_ssm_parameter" "datasource_driver" {
  type        = "String"
  name        = "/${local.component_name}/datasource/driver"
  value       = "com.mysql.jdbc.Driver"
  description = "データベース接続ドライバ"
}

# Secrets Manager
#
# tfstateファイルに秘匿情報を格納したくないため、認証情報はSecrets Managerに格納する
# TerraformでSecrets Managerのリソース作成は行うが、実際の値の登録はAWSマネジメントコンソールから行う

resource "aws_secretsmanager_secret" "datasource_password" {
  name        = "/${local.component_name}/datasource/password"
  description = "データベース接続パスワード"
  kms_key_id  = local.default_kms_key_arn
}
