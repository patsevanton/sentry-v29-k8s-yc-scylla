# Установка ScyllaDB через Operator в Kubernetes

Установка ScyllaDB Operator, ScyllaDB Manager и кластера ScyllaDB с помощью Helm.

**Важно:** ScyllaDB Operator должен быть в namespace `scylla-operator`, ScyllaDB Manager — в `scylla-manager`. Кластер ScyllaDB можно развернуть в любом namespace (в примере — `scylla`).

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install --wait prometheus-operator-crds prometheus-community/prometheus-operator-crds --version 20.0.0
```

## 1. Cert Manager (для webhook-сертификатов оператора)

Нужен для самоподписанных сертификатов оператора. Если cert-manager уже установлен — шаг пропустить.

```bash
helm repo add jetstack https://charts.jetstack.io --force-update

# Install the cert-manager helm chart
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.3 \
  --set crds.enabled=true \
  --wait
```

Дождаться готовности подов:

```bash
kubectl wait -n cert-manager --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager --timeout=120s
```


## 2. Helm-репозиторий ScyllaDB

```bash
helm repo add scylla https://scylla-operator-charts.storage.googleapis.com/stable
helm repo update
```

## 3. ScyllaDB Operator

```bash
helm upgrade --install scylla-operator scylla/scylla-operator \
  --create-namespace \
  --namespace scylla-operator \
  --wait
```


## 4. Кластер ScyllaDB

**Память:** Scylla требует не менее **1 GiB на шард** (иначе падает с `memory per shard too low` и API на порту 10000 не поднимается). В values задавайте `memory` не меньше **4Gi** на rack (оператор могут оставлять процессу меньше видимой памяти).

```bash
helm upgrade --install scylla scylla/scylla \
  --namespace scylla \
  --create-namespace \
  -f values-scylla.yaml \
  --wait
```

Дождаться готовности подов кластера:

```bash
kubectl -n scylla wait --for=condition=ready pod -l app.kubernetes.io/name=scylla --timeout=600s
```


## 5. ScyllaDB Manager

Устанавливать только после того, как кластер ScyllaDB готов и принимает соединения (иначе Manager падает с таймаутом при миграциях БД). Для внутреннего кластера Manager в `values-scylla-manager.yaml` задайте `scylla.racks[].resources.memory` не меньше **4Gi** (как для основного кластера).

```bash
helm upgrade --install scylla-manager scylla/scylla-manager \
  --create-namespace \
  --namespace scylla-manager \
  -f values-scylla-manager.yaml \
  --wait
```


## 6. Проверка

```bash
kubectl -n scylla get pods
kubectl -n scylla get scyllaclusters
kubectl -n scylla-operator get pods
```

Подключение к кластеру (CQL, порт 9042):

```bash
kubectl -n scylla exec -it scylla-dc1-rack1-0 -- cqlsh
```


## Удаление

В обратном порядке установки:

```bash
helm uninstall scylla -n scylla
helm uninstall scylla-manager -n scylla-manager
helm uninstall scylla-operator -n scylla-operator
kubectl delete namespace scylla scylla-manager scylla-operator
# при необходимости:
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```
