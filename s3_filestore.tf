# Статический ключ доступа для filestore
resource "yandex_iam_service_account_static_access_key" "filestore_bucket_key" {
  service_account_id = yandex_iam_service_account.sa_s3.id
  description        = "static access key for sentry filestore"
}

# Бакет для Filestore (nodestore в ScyllaDB — отдельный s3 бакет не создаётся)
resource "yandex_storage_bucket" "filestore" {
  bucket     = local.filestore_bucket
  folder_id  = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
  access_key = yandex_iam_service_account_static_access_key.filestore_bucket_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.filestore_bucket_key.secret_key

  lifecycle_rule {
    id      = "delete-after-30-days"
    enabled = true
    expiration {
      days = 30
    }
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.sa_admin_s3]
}

output "access_key_for_filestore_bucket" {
  description = "access_key filestore_bucket"
  value       = yandex_storage_bucket.filestore.access_key
  sensitive   = true
}

output "secret_key_for_filestore_bucket" {
  description = "secret_key filestore_bucket"
  value       = yandex_storage_bucket.filestore.secret_key
  sensitive   = true
}
