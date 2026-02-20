# sentry-v29-k8s-yc-elastic

Развёртывание Sentry v29.2.0 в Yandex Cloud на Kubernetes. ScyllaDB для nodestore; ClickHouse, PostgreSQL, Redis; S3 только для filestore; Kafka через operator (в кластере).

## Terraform

Инфраструктура: VPC, Managed Kubernetes, ClickHouse, PostgreSQL, Redis, S3. Kafka разворачивается в кластере через operator (например Strimzi).

```bash
export YC_FOLDER_ID='ваш folder'
terraform init
terraform apply
```

Переменные — в `variables.tf` (filestore, ScyllaDB, DNS, Sentry). После apply создаётся `values_sentry.yaml`.

Подключение к кластеру:
```bash
yc managed-kubernetes cluster get-credentials --id $(terraform output -raw k8s_cluster_id) --external --force
```
