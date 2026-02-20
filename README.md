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
helm repo update
helm upgrade --install clickhouse-operator altinity/altinity-clickhouse-operator \
  --version 0.26.0 \
  --namespace clickhouse-operator \
  --create-namespace \
  --wait
```

Оператор будет наблюдать за namespace `clickhouse`, где будет установлен ClickHouse.

**Вариант через ClickHouseOperatorConfiguration** (наблюдение за событиями в ns `clickhouse`):

```yaml
apiVersion: "clickhouse.altinity.com/v1"
kind: "ClickHouseOperatorConfiguration"
metadata:
  name: "watch-clickhouse-namespace"
spec:
  watch:
    namespaces:
    - "clickhouse"
```

Применить: `kubectl apply -f clickhouse-operator-config.yaml` (в ns, где установлен оператор, или как глобальная конфигурация по документации оператора).

**1.2. Создание ClickHouse**:

```bash
kubectl apply -f clickhouse.yaml
```

