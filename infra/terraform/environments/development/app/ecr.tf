# ECR：コンテナレジストリ
#
# Dockerイメージを保存する。
# ECRライフサイクルポリシーはデプロイ方式によって調整が必要。

locals {
  # デプロイ対象のDockerタグ
  # AWSアカウントごとに異なる値を設定する
  tag_prefix_list = [local.image_tag]
}

# ECRリポジトリ
resource "aws_ecr_repository" "app" {
  name = local.app_ecr_repository_name

  # イメージタグを変更可能にするかどうか指定する
  # IMMUTABLEを指定すると、イメージタグを上書きできなくなる
  image_tag_mutability = "MUTABLE"

  # プッシュ時にセキュリティスキャンを実行する
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECRライフサイクルポリシー
#
# リポジトリごとに保存できるイメージ数は10,000という制約があるので
# 不要なイメージを自動削除できるようにする
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        # 指定したタグの最新のイメージ1個は削除しない
        rulePriority = 1
        description  = "Keep [${join(", ", local.tag_prefix_list)}] tagged latest image, never delete"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = local.tag_prefix_list
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        # タグの有無に関わらず最新のイメージ30個を保持する
        rulePriority = 2
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
