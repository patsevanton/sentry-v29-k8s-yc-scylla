# # Создание кластера Redis в Yandex Managed Service for Redis
# resource "yandex_mdb_redis_cluster" "sentry" {
#   name        = "sentry"
#   folder_id   = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
#   network_id  = yandex_vpc_network.sentry.id
#   environment = "PRODUCTION"
#   tls_enabled = true
# 
#   config {
#     password         = local.redis_password
#     maxmemory_policy = "ALLKEYS_LRU"
#     version          = "7.2-valkey"
#   }
# 
#   resources {
#     resource_preset_id = "hm3-c2-m8"
#     disk_type_id       = "network-ssd"
#     disk_size          = 65
#   }
# 
#   host {
#     zone      = "ru-central1-a"
#     subnet_id = yandex_vpc_subnet.sentry-a.id
#   }
# }
# 
# output "externalRedis" {
#   value = {
#     host     = "c-${yandex_mdb_redis_cluster.sentry.id}.rw.mdb.yandexcloud.net"
#     port     = 6380
#     password = local.redis_password
#   }
#   sensitive = true
# }
