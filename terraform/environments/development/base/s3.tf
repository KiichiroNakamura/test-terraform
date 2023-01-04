# S3アクセスログバケット
#
# S3自体へのアクセスログを保存するためのバケット。
# S3バケット作成時に、このS3バケットをアクセスログの保存先として指定する。
# https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/dev/ServerLogs.html

module "s3_access_log_bucket" {
  source = "git@github.com:biglobe-isp/terraform-aws-s3-access-log-bucket.git?ref=tags/v0.3.0"

  name            = "s3-access-log-${local.account_alias}"
  expiration_days = local.expiration_days
  force_destroy = true
}
