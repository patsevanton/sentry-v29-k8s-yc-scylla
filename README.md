# Развёртывание Sentry v29.3.0 в Yandex Cloud на Kubernetes. 

### 0. Подготовка

Создайте необходимые namespace и подключите необходимые helm репозитории

```bash
kubectl create namespace clickhouse
```

### 1. ClickHouse


**1.1. Установка Altinity ClickHouse Operator**:

```bash
helm repo add altinity https://helm.altinity.com
helm update
helm upgrade --install clickhouse-operator altinity/altinity-clickhouse-operator \
  --namespace clickhouse-operator \
  --create-namespace \
  --set watchNamespaces[0]=clickhouse
```

Оператор будет наблюдать за namespace `clickhouse`, где будет установлен ClickHouse.

**1.2. Создание ClickHouse**:

```bash
kubectl apply -f clickhouse.yaml
kubectl -n clickhouse get clickhouseinstallation
kubectl -n clickhouse get pods -l clickhouse.altinity.com/chi=sentry-clickhouse
kubectl -n clickhouse wait --for=condition=ready pod -l clickhouse.altinity.com/chi=sentry-clickhouse --timeout=300s
kubectl -n clickhouse get svc -l clickhouse.altinity.com/chi=sentry-clickhouse
```

