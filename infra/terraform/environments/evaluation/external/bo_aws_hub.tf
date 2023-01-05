# BO-AWS-HUBとの連携を前提としたプライベートホストゾーン
#
# BOWS内のシステムはすべてBO-AWS-HUB経由でアクセスする。
# そのためALBなどに関連付けるRoute53レコードには、BO-AWS-HUBと連携済みのホストゾーンを使う必要がある。
#
# プライベートホストゾーン作成後、BO-AWS-HUB側の作業も必要。
# https://github.com/biglobe-isp/bo-aws-hub

# プライベートホストゾーン
resource "aws_route53_zone" "bows" {
  name    = local.zone_name
  comment = "BO-AWS-HUBへ公開するプライベートホストゾーン。BO-AWS-HUBとZone Associateしている。"

  vpc {
    vpc_id = local.vpc_id
  }

  # 別アカウントのVPCと Associate していると削除対象になるので、無視設定をいれる
  lifecycle {
    ignore_changes = [vpc]
  }
}

# BO-AWS-HUBへ関連付けるホストゾーンID
output "private_host_zone_id" {
  value = aws_route53_zone.bows.id
}
