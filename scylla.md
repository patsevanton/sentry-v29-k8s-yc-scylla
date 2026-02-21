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
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
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


## 4. ScyllaDB Manager

```bash
helm upgrade --install scylla-manager scylla/scylla-manager \
  --create-namespace \
  --namespace scylla-manager \
  --set "scylla.datacenter=manager-dc" \
  --set "scylla.racks[0].name=manager-rack" \
  --set "scylla.racks[0].members=1" \
  --set "scylla.racks[0].storage.storageClassName=yc-network-ssd" \
  --set "scylla.racks[0].storage.capacity=8Gi" \
  --set "scylla.racks[0].resources.limits.cpu=1" \
  --set "scylla.racks[0].resources.limits.memory=1Gi" \
  --set "scylla.racks[0].resources.requests.cpu=1" \
  --set "scylla.racks[0].resources.requests.memory=1Gi" \
  --wait
```


## 5. Кластер ScyllaDB


```bash
helm upgrade --install scylla scylla/scylla \
  --create-namespace \
  --namespace scylla \
  --set datacenter=dc1 \
  --set "racks[0].name=rack1" \
  --set "racks[0].members=2" \
  --set "racks[0].storage.storageClassName=yc-network-ssd" \
  --set "racks[0].storage.capacity=8Gi" \
  --set "racks[0].resources.limits.cpu=1" \
  --set "racks[0].resources.limits.memory=1Gi" \
  --set "racks[0].resources.requests.cpu=1" \
  --set "racks[0].resources.requests.memory=1Gi" \
  --wait
```

Либо создать файл `values-scylla.yaml` и установить с ним (подставьте свой StorageClass и размер):

```yaml
datacenter: dc1
racks:
  - name: rack1
    members: 2
    storage:
      storageClassName: yc-network-ssd   # для Yandex Cloud; в других облаках — свой SC
      capacity: 8Gi                      # для Yandex: размер кратный 4 Gi
    resources:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 1
        memory: 1Gi
```

```bash
helm upgrade --install scylla scylla/scylla \
  --namespace scylla \
  --create-namespace \
  -f values-scylla.yaml \
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
