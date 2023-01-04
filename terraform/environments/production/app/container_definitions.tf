# container_definitionsへ指定するパラメータの定義
#
# container_definitionsはオンラインとバッチで共通部分が多い上に複雑なので切り出す。

# アプリケーションのcontainer_definitionsへ指定するパラメータの定義
locals {
  # データベース接続に必要な環境変数をParameter StoreやSecrets Managerから注入する
  datasource_secrets = [
    {
      name      = "SPRING_DATASOURCE_URL"
      valueFrom = data.aws_ssm_parameter.datasource_url.name
    },
    {
      name      = "SPRING_DATASOURCE_DRIVER_CLASS_NAME"
      valueFrom = data.aws_ssm_parameter.datasource_driver.name
    },
    {
      name      = "SPRING_DATASOURCE_USERNAME"
      valueFrom = data.aws_ssm_parameter.datasource_username.name
    },
    {
      name      = "SPRING_DATASOURCE_PASSWORD"
      valueFrom = data.aws_secretsmanager_secret.datasource_password.arn
    },
  ]

  # SFTPに必要な環境変数をSecrets Managerから注入する
  ssh_secrets = [
    # {
    #   name      = "SSH_ID_RSA"
    #   valueFrom = data.aws_secretsmanager_secret.ssh_id_rsa.arn
    # },
    # {
    #   name      = "SSH_ID_RSA_PASSPHRASE"
    #   valueFrom = data.aws_secretsmanager_secret.ssh_id_rsa_passphrase.arn
    # },
    # {
    #   name      = "SSH_KNOWN_HOSTS"
    #   valueFrom = data.aws_secretsmanager_secret.ssh_known_hosts.arn
    # },
  ]

  # 直接平文で注入する環境変数（online／batchで共通）
  environment = [
    {
      name  = "BIGLOBE_NOTIFICATION_MAIL_SMTPHOST"
      value = local.bo_smtp_server_fqdn
    },
    {
      name  = "BIGLOBE_NOTIFICATION_MAIL_SMTPPORT"
      value = local.bo_smtp_server_port
    },
    # {
    #   name  = "BO_CAP_SFTP_HOST"
    #   value = local.bo_cap_sftp_fqdn
    # },
  ]

  # 直接平文で注入する環境変数（online）
  online_environment = [
    {
      name  = "BIGLOBE_SCENARIO_HTTP_BASEURL"
      value = "${local.online_bo_aws_hub_url}/scenario"
    },
    {
      name  = "MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_NAMESPACE"
      value = "${local.component_name}/${local.online_component_type}/Micrometer"
    },
  ]

  # 直接平文で注入する環境変数（batch）
  batch_environment = [
    {
      name  = "BIGLOBE_SCENARIO_HTTP_BASEURL"
      value = "${local.batch_bo_aws_hub_url}/scenario"
    },
    {
      name  = "MANAGEMENT_METRICS_EXPORT_CLOUDWATCH_NAMESPACE"
      value = "${local.component_name}/${local.batch_component_type}/Micrometer"
    },
  ]

  # ポートマッピング
  port_mappings = [
    {
      protocol      = "tcp"
      containerPort = local.container_port
      hostPort      = local.container_port
    }
  ]
}

# Parameter Store
data "aws_ssm_parameter" "datasource_url" {
  name = "/${local.component_name}/datasource/url"
}

data "aws_ssm_parameter" "datasource_driver" {
  name = "/${local.component_name}/datasource/driver"
}

data "aws_ssm_parameter" "datasource_username" {
  name = "/${local.component_name}/datasource/username"
}

# Secrets Manager
data "aws_secretsmanager_secret" "datasource_password" {
  name = "/${local.component_name}/datasource/password"
}

# data "aws_secretsmanager_secret" "ssh_id_rsa" {
#   name = "/${local.component_name}/ssh/id_rsa"
# }

# data "aws_secretsmanager_secret" "ssh_id_rsa_passphrase" {
#   name = "/${local.component_name}/ssh/id_rsa_passphrase"
# }

# data "aws_secretsmanager_secret" "ssh_known_hosts" {
#   name = "/${local.component_name}/ssh/known_hosts"
# }

# Fluent Bitのcontainer_definitionsへ指定するパラメータの定義
locals {
  # Fluent Bitイメージ
  fluent_bit_image = "${local.fluent_bit_image_name}:${local.fluent_bit_image_tag}"

  # Fluent Bitのメモリ予約サイズ(Mバイト)
  fluentbit_memory_reservation = 128

  # Fluent Bitへ直接平文で注入する環境変数（online／batchで共通）
  fluentbit_environment = [
    {
      name  = "CONTAINER_NAME"
      value = local.app_ecr_repository_name
    },
    {
      name  = "AWS_REGION"
      value = local.region
    },
  ]

  # Fluent Bitへ直接平文で注入する環境変数（online）
  online_fluentbit_environment = [
    {
      name  = "COMPONENT_NAME"
      value = local.online_component_type
    },
    {
      name  = "USUAL_LOG_GROUP_NAME"
      value = module.online_bows_cloudwatch_logs.usual_name
    },
  ]

  # Fluent Bitへ直接平文で注入する環境変数（batch）
  batch_fluentbit_environment = [
    {
      name  = "COMPONENT_NAME"
      value = local.batch_component_type
    },
    {
      name  = "USUAL_LOG_GROUP_NAME"
      value = module.batch_bows_cloudwatch_logs.usual_name
    },
  ]

  # Fluent Bitの設定
  firelens_configuration = {
    type = "fluentbit"
    options = {
      config-file-type  = "file"
      config-file-value = "/fluent-bit/etc/extra.conf"
    }
  }
}
