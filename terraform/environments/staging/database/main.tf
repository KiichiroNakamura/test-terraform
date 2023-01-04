# 環境ごとに異なるリソース・データソース・ローカル変数を定義
#
# 本ファイルとversions.tf以外は別環境へそのままコピーできるようにする。
# 環境差分を本ファイルに集約すると、別環境への展開時に構築の手間を最小化でき
# コードレビューも環境差分にのみフォーカスできるようになる。

locals {
  # DBクラスタインスタンス名のリスト
  #
  # 本番環境では複数のインスタンスを作成すること
  # シングルインスタンスで運用すると、復旧するまでサービスダウンが発生する
  #
  # カンマ区切りの文字列をsplit関数に渡してリストを生成している
  # カンマの後に空白文字を入れないように注意
  instance_names = split(",", "alpha,bravo")

  # Database Instanceのタイプ
  # Auroraで選択できるDBインスタンスタイプはこちら
  # r4, r3, t2 については古いバージョン用で、新しいバージョンでは選択できないようである。
  # r6gは、ARMベースのCPUなのでご利用は計画的に。
  #
  # https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.html
  #
  # インスタンスの選択戦略は以下のように考えている
  # 開発系、ステージングはコスト重視で t3
  # 本番系はCPUクレジット不足の性能低下を防ぐため r6g
  # ステージング系は本番系と条件をそろえて評価できるように r6g
  instance_class = "db.r6g.large"

  # Performance Insightsの有効化・無効化を指定するフラグ
  #
  # インスタンスクラスによっては有効化できないため、環境ごとに設定を切り替える。
  # t2/t3系の場合は有効にできずapplyすらできなくなるため無効化しておくこと。
  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/USER_PerfInsights.Overview.Engines.html
  performance_insights_enabled = "true"

  # バックアップ期間（日）
  # デフォルトは1日で、0〜35日の間で指定する
  # 本番環境では最大値の35日、それ以外の環境ではデフォルトの1日を推奨する
  backup_retention_period = "35"

  # CloudWatch Logsでのログ保存期間
  cloudwatch_logs_retention_in_days = "400"
}
