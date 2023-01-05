# 環境ごとに異なるリソース・データソース・ローカル変数を定義
#
# 本ファイルとversions.tf以外は別環境へそのままコピーできるようにする。
# 環境差分を本ファイルに集約すると、別環境への展開時に構築の手間を最小化でき
# コードレビューも環境差分にのみフォーカスできるようになる。

locals {
  # ECSサービスが維持するタスク数
  # 指定した数が1の場合、コンテナが異常終了するとECSサービスがタスクを再起動するまでアクセスできなくなる
  # そのため本番環境では2以上にする
  desired_count = "1"

  # ALBログ保存期間
  #
  # 本番のログ保存期間は「情報セキュリティ対策基準」で一年以上とされているので注意。
  # 本番以外はコスト削減のため、短くしても問題ない。
  # https://www.biglobe.net/pages/worddav/preview.action?fileName=MG-%E6%83%85%E3%82%BB001+%E6%83%85%E5%A0%B1%E3%82%BB%E3%82%AD%E3%83%A5%E3%83%AA%E3%83%86%E3%82%A3%E5%AF%BE%E7%AD%96%E5%9F%BA%E6%BA%96_20200302.pdf&pageId=48045213
  alb_log_expiration_days = "90"

  # ECSが保存するCloudWatch Logsでのログ保存期間
  cloudwatch_logs_retention_in_days = "90"
}
