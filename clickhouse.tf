# # Создание кластера ClickHouse в Яндекс Облаке
# resource "yandex_mdb_clickhouse_cluster" "sentry" {
#   folder_id   = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
#   name        = "sentry"
#   environment = "PRODUCTION"
#   network_id  = yandex_vpc_network.sentry.id
#   version     = "25.3"
# 
#   clickhouse {
#     resources {
#       resource_preset_id = "s3-c2-m8"
#       disk_type_id       = "network-ssd"
#       disk_size          = 70
#     }
#   }
# 
#   zookeeper {
#     resources {
#       resource_preset_id = "s3-c2-m8"
#       disk_type_id       = "network-ssd"
#       disk_size          = 34
#     }
#   }
# 
#   host {
#     type      = "CLICKHOUSE"
#     zone      = yandex_vpc_subnet.sentry-a.zone
#     subnet_id = yandex_vpc_subnet.sentry-a.id
#   }
# 
#   host {
#     type      = "ZOOKEEPER"
#     zone      = yandex_vpc_subnet.sentry-a.zone
#     subnet_id = yandex_vpc_subnet.sentry-a.id
#   }
# 
#   host {
#     type      = "ZOOKEEPER"
#     zone      = yandex_vpc_subnet.sentry-b.zone
#     subnet_id = yandex_vpc_subnet.sentry-b.id
#   }
# 
#   host {
#     type      = "ZOOKEEPER"
#     zone      = yandex_vpc_subnet.sentry-d.zone
#     subnet_id = yandex_vpc_subnet.sentry-d.id
#   }
# 
#   timeouts {
#     create = "60m"
#     update = "60m"
#     delete = "60m"
#   }
# }
# 
# resource "yandex_mdb_clickhouse_database" "sentry" {
#   cluster_id = yandex_mdb_clickhouse_cluster.sentry.id
#   name       = "sentry"
# }
# 
# resource "yandex_mdb_clickhouse_user" "sentry" {
#   cluster_id = yandex_mdb_clickhouse_cluster.sentry.id
#   name       = local.clickhouse_user
#   password   = local.clickhouse_password
# 
#   permission {
#     database_name = yandex_mdb_clickhouse_database.sentry.name
#   }
# 
#   depends_on = [yandex_mdb_clickhouse_database.sentry]
# }
# 
# output "externalClickhouse" {
#   value = {
#     host     = yandex_mdb_clickhouse_cluster.sentry.host[0].fqdn
#     database = yandex_mdb_clickhouse_database.sentry.name
#     httpPort = 8123
#     tcpPort  = 9000
#     username = local.clickhouse_user
#     password = local.clickhouse_password
#   }
#   sensitive = true
# }
