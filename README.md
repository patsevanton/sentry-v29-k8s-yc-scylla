# Развёртывание Sentry v29.3.0 в Yandex Cloud на Kubernetes. 

### 0. Подготовка (создать namespace и репозитории)

Выполните этот шаг перед шагом 1.1 — оператор устанавливается в namespace `clickhouse-operator`, ClickHouse в namespace `clickhouse`, Sentry в namespace `sentry`.

```bash
kubectl create namespace clickhouse-operator
kubectl create namespace clickhouse
kubectl create namespace sentry
helm repo add altinity https://helm.altinity.com
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo update
```

### 1. ClickHouse (в v29 внешний ClickHouse обязателен)

По [документации Sentry](https://github.com/sentry-kubernetes/charts/blob/develop/charts/sentry/docs/external-clickhouse.md) используется внешний ClickHouse через [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator).

**1.1. Установка Altinity ClickHouse Operator** (ставим в namespace `clickhouse-operator`):

Настройка `watchNamespaces` выполняется через файл `values-clickhouse-operator.yaml`:

```bash
helm upgrade --install clickhouse-operator altinity/altinity-clickhouse-operator \
  --namespace clickhouse-operator \
  -f values-clickhouse-operator.yaml
```

Оператор будет наблюдать за namespace `clickhouse`, где будет установлен ClickHouse.

**1.2. Создание ClickHouse (CHI)**:

```bash
kubectl apply -f clickhouse.yaml
kubectl -n clickhouse get clickhouseinstallation
kubectl -n clickhouse get pods -l clickhouse.altinity.com/chi=sentry-clickhouse
kubectl -n clickhouse wait --for=condition=ready pod -l clickhouse.altinity.com/chi=sentry-clickhouse --timeout=300s
kubectl -n clickhouse get svc -l clickhouse.altinity.com/chi=sentry-clickhouse
```

Для установки Sentry см. [README-sentry.md](README-sentry.md).
