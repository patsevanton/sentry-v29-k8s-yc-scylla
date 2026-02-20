# sentry-v29-k8s-yc-scylla

Развёртывание Sentry v29.2.0 в Yandex Cloud на Kubernetes. ScyllaDB для nodestore; ClickHouse, PostgreSQL, Redis; S3 только для filestore; Kafka через operator (в кластере).

## Установка Sentry v29.2.0 (минимальный режим)

Чарт: [sentry-kubernetes/charts sentry-v29.2.0](https://github.com/sentry-kubernetes/charts/releases/tag/sentry-v29.2.0). Требуется `kubectl` и `helm`, доступ в кластер.

### 1. Репозиторий и namespace

```bash
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo update
kubectl create namespace sentry
```

### 2. ClickHouse (в v29 внешний ClickHouse обязателен)

```bash
kubectl apply -f k8s-clickhouse-minimal.yaml
kubectl -n sentry get pods -l app=clickhouse
kubectl -n sentry wait --for=condition=ready pod -l app=clickhouse --timeout=120s
kubectl -n sentry logs -l app=clickhouse --tail=10
```

### 3. Установка Sentry

```bash
helm install sentry sentry/sentry --version 29.2.0 -n sentry \
  -f values-sentry-minimal.yaml --timeout=900s
```

Без `--wait` установка не будет ждать готовности всех подов; после установки проверьте состояние и логи (шаг 5). При необходимости обновление:

```bash
helm upgrade sentry sentry/sentry --version 29.2.0 -n sentry \
  -f values-sentry-minimal.yaml --timeout=600s
```

### 4. Топик Kafka для taskbroker-ingest (если под в CrashLoopBackOff)

Если `sentry-taskbroker-ingest-0` в CrashLoopBackOff из‑за отсутствия топика:

```bash
kubectl -n sentry exec sentry-kafka-controller-0 -- kafka-topics.sh \
  --bootstrap-server localhost:9092 --create --topic taskworker-ingest \
  --partitions 1 --replication-factor 1
kubectl -n sentry delete pod sentry-taskbroker-ingest-0
```

### 5. Проверка подов и логов

```bash
kubectl -n sentry get pods
kubectl -n sentry logs deployment/sentry-snuba-api --tail=20
kubectl -n sentry logs sentry-taskbroker-ingest-0 --tail=20
kubectl -n sentry logs deployment/sentry-web --tail=20
```

Доступ к веб-интерфейсу — через Ingress (hostname в `values-sentry-minimal.yaml`, по умолчанию `sentry.local`) или `kubectl port-forward`:

```bash
kubectl -n sentry port-forward svc/sentry-web 9000:9000
# Открыть http://localhost:9000, логин admin@sentry.local / admin
```

### Удаление

```bash
helm uninstall sentry -n sentry
kubectl delete -f k8s-clickhouse-minimal.yaml
kubectl delete namespace sentry
```

---

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
