# # Генерация конфигурации Sentry из шаблона (nodestore в ScyllaDB, без s3_nodestore)
# locals {
#   # Блок sentryConfPy для nodestore в ScyllaDB (sentry-cassandra-nodestore, ScyllaDB совместим с Cassandra)
#   nodestore_scylladb_sentry_conf_py = length(var.scylladb_contact_points) > 0 ? join("\n", [
#     "INSTALLED_APPS.append('sentry_nodestore_cassandra')",
#     "SENTRY_NODESTORE = 'sentry_nodestore_cassandra.CassandraNodeStorage'",
#     "SENTRY_NODESTORE_OPTIONS = {",
#     "    'contact_points': ${jsonencode(var.scylladb_contact_points)},",
#     "    'keyspace': '${var.scylladb_keyspace}',",
#     "}",
#     ]) : join("\n", [
#     "# Nodestore: задайте variable scylladb_contact_points (и опционально scylladb_keyspace) для ScyllaDB.",
#     "# Пример: scylladb_contact_points = [\"scylla-0.scylla.svc:9042\"]",
#     "# И установите в образе Sentry: pip install sentry-cassandra-nodestore",
#   ])
# 
#   sentry_config = templatefile("${path.module}/values_sentry.yaml.tpl", {
#     sentry_admin_password    = local.sentry_admin_password
#     user_email               = var.user_email
#     system_url               = var.system_url
#     nginx_enabled            = false
#     ingress_enabled          = true
#     ingress_hostname         = var.ingress_hostname
#     ingress_class_name       = "nginx"
#     ingress_regex_path_style = "nginx"
#     ingress_annotations = {
#       proxy_body_size      = "200m"
#       proxy_buffers_number = "16"
#       proxy_buffer_size    = "32k"
#     }
#     nodestore_scylladb_sentry_conf_py = local.nodestore_scylladb_sentry_conf_py
#     filestore = {
#       s3 = {
#         accessKey  = yandex_storage_bucket.filestore.access_key
#         secretKey  = yandex_storage_bucket.filestore.secret_key
#         bucketName = yandex_storage_bucket.filestore.bucket
#       }
#     }
#     postgresql_enabled = false
#     external_postgresql = {
#       password = local.postgres_password
#       host     = "c-${yandex_mdb_postgresql_cluster.postgresql_cluster.id}.rw.mdb.yandexcloud.net"
#       port     = 6432
#       username = yandex_mdb_postgresql_user.postgresql_user.name
#       database = yandex_mdb_postgresql_database.postgresql_database.name
#     }
#     redis_enabled = false
#     external_redis = {
#       password = local.redis_password
#       host     = "c-${yandex_mdb_redis_cluster.sentry.id}.rw.mdb.yandexcloud.net"
#       port     = 6380
#     }
#     external_kafka = {
#       cluster = []
#       sasl = {
#         mechanism = "SCRAM-SHA-512"
#         username  = ""
#         password  = ""
#       }
#       security = {
#         protocol = "SASL_SSL"
#       }
#     }
#     kafka_enabled      = true
#     zookeeper_enabled  = false
#     clickhouse_enabled = false
#     external_clickhouse = {
#       password = local.clickhouse_password
#       host     = yandex_mdb_clickhouse_cluster.sentry.host[0].fqdn
#       database = yandex_mdb_clickhouse_database.sentry.name
#       httpPort = 8123
#       tcpPort  = 9000
#       username = local.clickhouse_user
#     }
#   })
# }
# 
# resource "local_file" "values_sentry_yaml" {
#   content  = local.sentry_config
#   filename = "${path.module}/values_sentry.yaml"
# }
