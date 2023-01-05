# KMS：暗号鍵管理
#
# AWSアカウントごとにひとつカスタマーマスターキーを作成する。
# 理論上は用途ごとにカスタマーマスターキーを作成したほうがセキュアだが、
# 管理コストが上がって適切な管理が難しいため、単一のリソースを使う方針とする。
# https://github.com/biglobe-isp/Freyja/issues/959

module "default_kms" {
  source = "git@github.com:biglobe-isp/terraform-aws-kms.git?ref=tags/v0.2.0"

  name        = "alias/default"
  description = "Default customer managed CMK"
}
