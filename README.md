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
  --version 0.25.6 \
  --namespace clickhouse-operator \
  --create-namespace \
  --wait
```

Оператор через ClickHouseOperatorConfiguration будет наблюдать за namespace `clickhouse`


```bash
kubectl apply -n clickhouse-operator -f clickhouse-operator-config.yaml 
```

Перезапуск оператора, чтобы подхватить ClickHouseOperatorConfiguration:

```bash
kubectl rollout restart deployment/clickhouse-operator -n clickhouse-operator
```

**1.2. Создание ClickHouse**:

```bash
kubectl apply -f clickhouse.yaml
```

