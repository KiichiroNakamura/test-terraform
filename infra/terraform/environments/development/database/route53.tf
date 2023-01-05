# Route 53：CNAMEレコード
#
# データベースへの接続はRDSが払い出したエンドポイント名ではなく、プライベートなドメイン名を使って接続する。
# これにより将来的にデータベースを切り替える場合も、アプリケーションの設定変更なしに接続先を変更可能になる。

# MasterのCNAMEレコード
resource "aws_route53_record" "master_aurora" {
  zone_id = aws_route53_zone.db_private.zone_id
  name    = local.master_host_name
  type    = "CNAME"
  ttl     = "300"
  records = [module.aurora.endpoint]
}

# ReadレプリカのCNAMEレコード
resource "aws_route53_record" "readonly_aurora" {
  zone_id = aws_route53_zone.db_private.zone_id
  name    = local.readonly_host_name
  type    = "CNAME"
  ttl     = "300"
  records = [module.aurora.reader_endpoint]
}

# 自VPC内のデータベースでのみ使用するプライベートホストゾーン
resource "aws_route53_zone" "db_private" {
  name = "${local.component_name}.${local.subsystem_name}.db.private"

  vpc {
    vpc_id = local.vpc_id
  }
}
