# BOWSコミュニティの申請に利用する
#
# 全体設計は下記を参照すること
# https://github.com/biglobe-isp/bows-community/blob/main/document/maintainer/request_automation/README.md

# BOWSコミュニティ申請ワークフロー用IAMロール
# これはbows-communityリポジトリのGitHub Actionsから使用する特殊なIAMロールである
module "bows_community_gh_iam_role" {
  source = "git@github.com:biglobe-isp/terraform-aws-bows-community-gh-iam-role.git?ref=tags/v0.5.0"

  expiration_date = "2023-03-31"
}

# BOWSコミュニティ申請用コマンド出力モジュール
# GitHub CLIのコピペ用コマンドを生成してくれる
module "data_bows_community" {
  source = "git@github.com:biglobe-isp/terraform-aws-data-bows-community.git?ref=tags/v0.6.0"

  stack                           = "external"
  zone_name                       = aws_route53_zone.bows.name
  private_hosted_zone_id          = aws_route53_zone.bows.id
  bows_community_gh_iam_role_name = module.bows_community_gh_iam_role.name
  sub_system_name                 = local.subsystem_name
  service_fqdn                    = aws_route53_zone.public.name
  ns_records                      = aws_route53_zone.public.name_servers
}

output "request_command" {
  value = module.data_bows_community.request_command
}
