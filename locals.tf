# Получаем информацию о конфигурации клиента Yandex
data "yandex_client_config" "client" {}

# Генерация случайного пароля для ClickHouse
resource "random_password" "clickhouse" {
  length      = 20
  special     = false
  min_numeric = 4
  min_upper   = 4
}

# Генерация случайного пароля для Redis
resource "random_password" "redis" {
  length      = 20
  special     = false
  min_numeric = 4
  min_upper   = 4
}

# Генерация случайного пароля для PostgreSQL
resource "random_password" "postgres" {
  length      = 20
  special     = false
  min_numeric = 4
  min_upper   = 4
}

# Генерация случайного пароля для администратора Sentry
resource "random_password" "sentry_admin_password" {
  length      = 20
  special     = false
  min_numeric = 4
  min_upper   = 4
}

# Локальные переменные для настройки инфраструктуры (nodestore в ScyllaDB — s3_nodestore не используется)
locals {
  folder_id             = data.yandex_client_config.client.folder_id
  sentry_admin_password = random_password.sentry_admin_password.result
  clickhouse_user       = "sentry"
  clickhouse_password   = random_password.clickhouse.result
  redis_password        = random_password.redis.result
  postgres_password     = random_password.postgres.result
  filestore_bucket      = var.filestore_bucket_name
}

output "generated_passwords" {
  description = "Map of generated passwords for services"
  value = {
    clickhouse_password = random_password.clickhouse.result
    redis_password      = random_password.redis.result
    postgres_password   = random_password.postgres.result
  }
  sensitive = true
}
