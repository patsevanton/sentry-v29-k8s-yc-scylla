# Создание внешнего IP-адреса в Yandex Cloud
resource "yandex_vpc_address" "addr" {
  name = "sentry-pip"

  external_ipv4_address {
    zone_id = yandex_vpc_subnet.sentry-a.zone
  }
}

# # Создание публичной DNS-зоны в Yandex Cloud DNS (отключено для запуска только k8s)
# resource "yandex_dns_zone" "apatsev_org_ru" {
#   name             = var.dns_zone_name
#   zone             = var.dns_zone
#   public           = true
#   private_networks = [yandex_vpc_network.sentry.id]
# }
#
# # Создание DNS-записи типа A, указывающей на внешний IP
# resource "yandex_dns_recordset" "rs1" {
#   zone_id = yandex_dns_zone.apatsev_org_ru.id
#   name    = var.dns_record_name
#   type    = "A"
#   ttl     = 200
#   data    = [yandex_vpc_address.addr.external_ipv4_address[0].address]
# }
