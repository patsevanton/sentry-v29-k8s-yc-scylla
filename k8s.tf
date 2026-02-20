# Создание сервисного аккаунта для управления Kubernetes
resource "yandex_iam_service_account" "sa_k8s_editor" {
  folder_id = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
  name      = "sa-k8s-editor"
}

# Назначение роли "editor" сервисному аккаунту на уровне папки
resource "yandex_resourcemanager_folder_iam_member" "sa_k8s_editor_permissions" {
  folder_id = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa_k8s_editor.id}"
}

# Пауза, чтобы изменения IAM успели примениться до создания кластера
resource "time_sleep" "wait_sa" {
  create_duration = "20s"
  depends_on = [
    yandex_iam_service_account.sa_k8s_editor,
    yandex_resourcemanager_folder_iam_member.sa_k8s_editor_permissions
  ]
}

# Создание Kubernetes-кластера в Yandex Cloud
resource "yandex_kubernetes_cluster" "sentry" {
  name       = "sentry"
  folder_id  = coalesce(local.folder_id, data.yandex_client_config.client.folder_id)
  network_id = yandex_vpc_network.sentry.id

  master {
    version = "1.31"
    zonal {
      zone      = yandex_vpc_subnet.sentry-a.zone
      subnet_id = yandex_vpc_subnet.sentry-a.id
    }
    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.sa_k8s_editor.id
  node_service_account_id = yandex_iam_service_account.sa_k8s_editor.id
  release_channel         = "STABLE"
  depends_on              = [time_sleep.wait_sa]
}

# Группа узлов для Kubernetes-кластера
resource "yandex_kubernetes_node_group" "k8s_node_group" {
  description = "Node group for the Managed Service for Kubernetes cluster"
  name        = "k8s-node-group"
  cluster_id  = yandex_kubernetes_cluster.sentry.id
  version     = "1.31"

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location { zone = yandex_vpc_subnet.sentry-a.zone }
    location { zone = yandex_vpc_subnet.sentry-b.zone }
    location { zone = yandex_vpc_subnet.sentry-d.zone }
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat = true
      subnet_ids = [
        yandex_vpc_subnet.sentry-a.id,
        yandex_vpc_subnet.sentry-b.id,
        yandex_vpc_subnet.sentry-d.id
      ]
    }

    resources {
      memory = 20
      cores  = 4
    }

    boot_disk {
      type = "network-ssd"
      size = 128
    }
  }
}

# Настройка провайдера Helm для установки чарта в Kubernetes
provider "helm" {
  kubernetes {
    host                   = yandex_kubernetes_cluster.sentry.master[0].external_v4_endpoint
    cluster_ca_certificate = yandex_kubernetes_cluster.sentry.master[0].cluster_ca_certificate
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["k8s", "create-token"]
      command     = "yc"
    }
  }
}

# Установка ingress-nginx через Helm
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.10.6"
  namespace        = "ingress-nginx"
  create_namespace = true
  depends_on       = [yandex_kubernetes_cluster.sentry]

  set {
    name  = "controller.service.loadBalancerIP"
    value = yandex_vpc_address.addr.external_ipv4_address[0].address
  }
}

output "k8s_cluster_credentials_command" {
  value = "yc managed-kubernetes cluster get-credentials --id ${yandex_kubernetes_cluster.sentry.id} --external --force"
}
