#!/bin/bash
#
# Terraformセットアップスクリプト
#
# Terraformによる管理を始める前に
# Terraform実行に必須となるリソースをAWS上で作成する
# https://www.terraform.io/docs/backends/types/s3.html

set -e

# 必須ツールがインストールされているかチェック
echo "Check requirements"
if ! command -v aws >/dev/null 2>&1; then
  echo "Error: AWS CLI must be installed"
  exit 2
fi

echo "Start S3 bucket creation"

# AWSアカウントIDから環境名を取得
# BIGLOBEではAWSアカウントIDは「bgl-big1234-dev」のような書式なので、この書式を前提に実装している
REGION="ap-northeast-1"
AWS_ACCOUNT_ID=$(aws iam list-account-aliases --query AccountAliases[0] --output text --region "${REGION}")

# AWSアカウントIDからバケット名を作成
BUCKET_NAME="terraform-${AWS_ACCOUNT_ID}"

# S3バケットの作成
# https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
aws s3api create-bucket --bucket "${BUCKET_NAME}" --create-bucket-configuration LocationConstraint="${REGION}"

# バージョニングの設定
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-versioning.html
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled

# 暗号化の設定
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-encryption.html
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

# パブリックアクセスの設定
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-public-access-block.html
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" --public-access-block-configuration '{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}'

echo "Finished S3 bucket creation"
printf "\nCreated: \e[32m%-20s\e[m\n" "${BUCKET_NAME}"
