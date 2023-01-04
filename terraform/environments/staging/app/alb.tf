# アプリケーションロードバランサー
#
# オンラインとバッチで共用し、振り分けにはホストヘッダーを使用する。
# リスナールールとターゲットグループはECSと密結合なので、ECSと一緒に定義している。

module "alb" {
  source = "git@github.com:biglobe-isp/terraform-aws-alb.git?ref=tags/v0.1.0"

  name               = local.component_name
  port               = aws_security_group_rule.alb_ingress.from_port
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.alb.id]
  certificate_arn    = module.alb_acm_certificate.arn
  access_logs_bucket = module.alb_log_bucket.id
}

# ALBのセキュリティグループ
resource "aws_security_group" "alb" {
  name   = "${local.component_name}-alb"
  vpc_id = local.vpc_id

  tags = {
    "Name" = "${local.component_name}-alb"
  }
}

resource "aws_security_group_rule" "alb_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = local.bo_aws_hub_security_group_id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# AWS Certificate Manager：証明書管理
#
# ALBに設定するSSL証明書。
# 証明書の検証にDNS検証を用いるため、パブリックなドメインが必要。
#
# そのため事前にパブリックホストゾーンを作成し、
# さらにNSレコードをBO-AWS-Gatewayへ登録しておく必要がある。
#
# BO-AWS-Gatewayへの登録が完了していない場合、
# aws_acm_certificate_validationリソースによる証明書検証が無限に完了しなくなる。
# apply時にタイムアウトエラーが発生した場合は、BO-AWS-GatewayにNSレコードが存在するか確認すること。
module "alb_acm_certificate" {
  source = "git@github.com:biglobe-isp/terraform-aws-acm-certificate.git?ref=tags/v0.3.0"

  name        = "${local.component_name}-alb"
  domain_name = "*.${local.domain_name}"
  zone_id     = data.aws_route53_zone.public.zone_id
}

# パブリックホストゾーン
#
# BO-AWS-GatewayにNSレコードを登録済み
# SSL証明書の検証に用いるためパブリックにしている
data "aws_route53_zone" "public" {
  name         = local.zone_name
  private_zone = false
}

# ALBログバケット
module "alb_log_bucket" {
  source = "git@github.com:biglobe-isp/terraform-aws-alb-log-bucket.git?ref=tags/v0.3.0"

  name                  = "${local.component_name}-alb-log-${local.account_alias}"
  expiration_days       = local.alb_log_expiration_days
  logging_target_bucket = data.aws_s3_bucket.s3_access_log_bucket.id
}

# S3アクセスログバケット
data "aws_s3_bucket" "s3_access_log_bucket" {
  bucket = "s3-access-log-${local.account_alias}"
}
