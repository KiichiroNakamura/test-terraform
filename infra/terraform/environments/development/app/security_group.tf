# ECSのセキュリティグループ
#
# オンラインとバッチで共用する。
# ECSの前段にはALBがいるので、ALBからの通信を許可しておく。

# セキュリティグループ
resource "aws_security_group" "ecs" {
  name   = "${local.component_name}-ecs"
  vpc_id = local.vpc_id

  tags = {
    "Name" = "${local.component_name}-ecs"
  }
}

resource "aws_security_group_rule" "ecs_ingress" {
  type                     = "ingress"
  from_port                = local.container_port
  to_port                  = local.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
}

# VPCエンドポイントのIngressセキュリティグループルール
#
# セキュリティグループ自体は、baseディレクトリでVPCエンドポイントのリソースと一緒に定義されている。
resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  #security_group_id        = data.aws_security_group.default_vpc_endpoint.id
  security_group_id        = "sg-00368ed5a5e34f6b9"
}

data "aws_security_group" "default_vpc_endpoint" {
  name   = "default-vpc-endpoint"
  vpc_id = local.vpc_id
}

# Ingressセキュリティグループルール
#
# ECSのアプリケーションがデータベースへアクセスするために必要。
# セキュリティグループ自体は、databaseディレクトリでRDSのリソースと一緒に定義されている。
resource "aws_security_group_rule" "aurora_ingress" {
  type                     = "ingress"
  from_port                = data.aws_ssm_parameter.datasource_port.value
  to_port                  = data.aws_ssm_parameter.datasource_port.value
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
  security_group_id        = data.aws_security_group.aurora.id
}

data "aws_ssm_parameter" "datasource_port" {
  name = "/${local.component_name}/datasource/port"
}

data "aws_security_group" "aurora" {
  name = "${local.component_name}-aurora"
}
