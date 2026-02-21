# Установка ScyllaDB через Operator в Kubernetes

Установка ScyllaDB Operator, ScyllaDB Manager и кластера ScyllaDB с помощью Helm.

## Требования

- Kubernetes (поддерживаемые версии — [support matrix](https://operator.docs.scylladb.com/stable/support/releases.html#support-matrix))
- Helm 3+
- StorageClass для PersistentVolumes

**Важно:** ScyllaDB Operator должен быть в namespace `scylla-operator`, ScyllaDB Manager — в `scylla-manager`. Кластер ScyllaDB можно развернуть в любом namespace (в примере — `scylla`).

**Yandex Cloud:** в чарте по умолчанию указан `storageClassName: scylladb-local-xfs`, которого в Yandex Managed Kubernetes нет. Нужно явно задать существующий StorageClass (например `yc-network-hdd` или `yc-network-ssd`) и размер диска **кратный 4 Gi** (ограничение Yandex Disk), например `8Gi` или `10Gi`.

---

## 1. Cert Manager (для webhook-сертификатов оператора)

Нужен для самоподписанных сертификатов оператора. Если cert-manager уже установлен — шаг пропустить.

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

Дождаться готовности подов:

```bash
kubectl wait -n cert-manager --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager --timeout=120s
```

---

## 2. Helm-репозиторий ScyllaDB

```bash
helm repo add scylla https://scylla-operator-charts.storage.googleapis.com/stable
helm repo update
```

Проверка чартов:

```bash
helm search repo scylla
```

---

## 3. ScyllaDB Operator

```bash
helm upgrade --install scylla-operator scylla/scylla-operator \
  --create-namespace \
  --namespace scylla-operator \
  --wait
```

---

## 4. ScyllaDB Manager (опционально, для бэкапов и ремонта)

```bash
helm upgrade --install scylla-manager scylla/scylla-manager \
  --create-namespace \
  --namespace scylla-manager \
  --wait
```

---

## 5. Кластер ScyllaDB

Проверьте доступные StorageClass в кластере (для Yandex Cloud обычно `yc-network-hdd`, `yc-network-ssd`):

```bash
kubectl get storageclass
```

Минимальный кластер (один rack, 2 узла). **Для Yandex Cloud** задайте существующий `storageClassName` и размер кратный 4 Gi (например `8Gi`):

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
      storageClassName: yc-network-hdd   # для Yandex Cloud; в других облаках — свой SC
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

---

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

---

## Обновление CRD (при обновлении оператора)

Helm не обновляет CRD при upgrade. CRD нужно обновлять вручную по инструкции: [Upgrade of Scylla Operator](https://operator.docs.scylladb.com/stable/upgrade.html).

---

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
