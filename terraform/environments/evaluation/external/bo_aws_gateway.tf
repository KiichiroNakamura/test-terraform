# BO-AWS-Gatewayとの連携を前提としたパブリックホストゾーン
#
# BOWSではACM(AWS Certificate Manager)でSSL/TLS証明書を発行する。
# ACMの仕様上、証明書のDNS認証でパブリックホストゾーンが必要である。
#
# BOWSではBO-AWS-Gatewayで管理しているドメインのサブドメインを使用する設計としており
# パブリックホストゾーンを作成したら、別途BO-AWS-GatewayにNSレコードの登録が必要である。
# https://github.com/biglobe-isp/bo-aws-gateway

# パブリックホストゾーン
resource "aws_route53_zone" "public" {
  name    = local.zone_name
  comment = "SSL/TLS証明書の認証用パブリックホストゾーン。BO-AWS-GatewayにNSレコードを登録している。"
}

# BO-AWS-Gatewayへ登録するNSレコード
output "public_name_servers" {
  value = aws_route53_zone.public.name_servers
}
