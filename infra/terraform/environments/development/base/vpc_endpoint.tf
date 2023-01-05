# VPCエンドポイント
#
# AWSアカウント申請時に「VPCエンドポイント集約」へチェックを入れると
# 次のVPCエンドポイントは独自に作成する必要はない
#
# - ec2.ap-northeast-1.amazonaws.com
# - ec2messages.ap-northeast-1.amazonaws.com
# - logs.ap-northeast-1.amazonaws.com
# - monitoring.ap-northeast-1.amazonaws.com
# - ssm.ap-northeast-1.amazonaws.com
# - ssmmessages.ap-northeast-1.amazonaws.com
#
# そこで作成するVPCエンドポイントは集約されていないもののみ定義する

# module "default_bows_vpc_endpoints" {
#   source = "git@github.com:biglobe-isp/terraform-aws-bows-vpc-endpoints.git?ref=tags/v0.4.0"

#   name_prefix        = "default"
#   vpc_id             = local.vpc_id
#   subnet_ids         = local.private_subnet_ids
#   security_group_ids = [aws_security_group.default_vpc_endpoint.id]
# }

# VPCエンドポイントのネットワークインターフェイスに紐付けるセキュリティグループ
# HTTPS（443番ポート）を許可する必要がある
# https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/vpce-interface.html
resource "aws_security_group" "default_vpc_endpoint" {
  name   = "default-vpc-endpoint"
  vpc_id = local.vpc_id
  tags = {
    "Name" = "default-vpc-endpoint"
  }

  lifecycle {
    # 別tfstateファイルで管理しているaws_security_group_ruleリソースの影響を受けないようにする
    ignore_changes = [ingress]
  }
}

resource "aws_security_group_rule" "default_vpc_endpoint_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.default_vpc_endpoint.id
}
