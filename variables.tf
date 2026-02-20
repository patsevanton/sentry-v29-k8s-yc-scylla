# variable "filestore_bucket_name" {
#   description = "S3 bucket name for Sentry filestore"
#   type        = string
#   default     = "sentry-bucket-filestore"
# }
# 
# # ScyllaDB для Nodestore (Cassandra-совместимый, например через operator)
# variable "scylladb_contact_points" {
#   description = "ScyllaDB contact points for nodestore (e.g. [\"scylla-0.scylla:9042\", \"scylla-1.scylla:9042\"])"
#   type        = list(string)
#   default     = []
# }
# 
# variable "scylladb_keyspace" {
#   description = "ScyllaDB keyspace name for nodestore"
#   type        = string
#   default     = "sentry_nodestore"
# }
# 
# variable "dns_zone_name" {
#   description = "DNS zone name in Yandex Cloud"
#   type        = string
#   default     = "apatsev-org-ru-zone"
# }
# 
# variable "dns_zone" {
#   description = "DNS zone (e.g. apatsev.org.ru.)"
#   type        = string
#   default     = "apatsev.org.ru."
# }
# 
# variable "dns_record_name" {
#   description = "DNS A record name for Sentry (e.g. sentry.apatsev.org.ru.)"
#   type        = string
#   default     = "sentry.apatsev.org.ru."
# }
# 
# variable "user_email" {
#   description = "Sentry admin user email"
#   type        = string
#   default     = "admin@sentry.apatsev.org.ru"
# }
# 
# variable "system_url" {
#   description = "Sentry system URL"
#   type        = string
#   default     = "http://sentry.apatsev.org.ru"
# }
# 
# variable "ingress_hostname" {
#   description = "Ingress hostname for Sentry"
#   type        = string
#   default     = "sentry.apatsev.org.ru"
# }
