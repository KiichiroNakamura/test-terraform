# Aurora向けパスワードの設定
#
# null_resourceリソースを使ってコマンドラインを実行する
# 実行環境はAWS CLIインストール済みのmacOSを前提とする

# rootパスワードの変更
# tfstateファイルにパスワードが平文で保存されるのを避けるため、AWS CLIでパスワードを変更する
# なおrootパスワードは保存せず、必要に応じてaws rds modify-db-clusterコマンドで変更すること
resource "null_resource" "root_password" {
  provisioner "local-exec" {
    command = local.root_password
  }

  triggers = {
    command = local.root_password
  }

  depends_on = [module.aurora]
}

# アプリケーション用接続パスワードのSecrets Managerへの登録
# tfstateファイルにパスワードが平文で保存されるのを避けるため、AWS CLIでSecrets Managerへ登録する
# resource "null_resource" "user_password" {
#   provisioner "local-exec" {
#     command = local.user_password
#   }

#   triggers = {
#     command = local.user_password
#   }
# }

locals {
  root_password = <<-EOT
    aws rds modify-db-cluster --apply-immediately \
    --db-cluster-identifier ${local.component_name} \
    --master-user-password "${local.generate_password}"
  EOT

#   user_password = <<-EOT
#     aws secretsmanager put-secret-value \
#     --secret-id ${aws_secretsmanager_secret.datasource_password.name} \
#     --secret-id ${aws_secretsmanager_secret.datasource_password.name} \
#     --secret-string "${local.generate_password}" \
#   EOT

  # パスワードは「/, ", @」を除いた、最大41文字までのアスキー印字文字にする
  # https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/APIReference/API_CreateDBCluster.html
  generate_password = "$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9%^_+=()[]{}<>' | fold -w 40 | head -1)"
}
