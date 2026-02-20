# Создание сервисного аккаунта в Yandex IAM для S3 (filestore)
resource "yandex_iam_service_account" "sa_s3" {
  name = "sa-sentry-s3"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_admin_s3" {
  folder_id = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa_s3.id}"
}
