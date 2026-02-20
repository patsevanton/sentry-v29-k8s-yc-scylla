# Развёртывание Sentry v29.2.0 в Yandex Cloud на Kubernetes. 

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

```bash
helm upgrade --install clickhouse-operator altinity/altinity-clickhouse-operator \
  --namespace clickhouse-operator \
  --set watchNamespaces[0]=clickhouse
```

**Важно:** Если оператор не создаёт поды ClickHouse после применения `clickhouse.yaml`, проверьте ConfigMap оператора:
```bash
kubectl -n clickhouse-operator get configmap clickhouse-operator-altinity-clickhouse-operator-files -o jsonpath='{.data.config\.yaml}' | grep -A 3 "watch:"
```

Если `watch.namespaces` пустой (`[]`), обновите ConfigMap вручную:
```bash
kubectl -n clickhouse-operator get configmap clickhouse-operator-altinity-clickhouse-operator-files -o yaml | \
  python3 -c "import sys, yaml; data=yaml.safe_load(sys.stdin); data['data']['config.yaml'] = yaml.safe_load(data['data']['config.yaml']); data['data']['config.yaml']['watch']['namespaces']=['clickhouse']; data['data']['config.yaml'] = yaml.dump(data['data']['config.yaml'], default_flow_style=False, allow_unicode=True); print(yaml.dump(data, default_flow_style=False, allow_unicode=True))" | \
  kubectl -n clickhouse-operator replace -f -
kubectl -n clickhouse-operator delete pod -l app.kubernetes.io/name=altinity-clickhouse-operator
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

### 2. Репозиторий Sentry

Репозиторий и namespace уже созданы в шаге 0. При необходимости повторите:

```bash
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo update
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

### 4. Проверка подов и логов

```bash
kubectl -n sentry get pods
kubectl -n sentry logs deployment/sentry-snuba-api --tail=20
kubectl -n sentry logs sentry-taskbroker-ingest-0 --tail=20
kubectl -n sentry logs deployment/sentry-web --tail=20
```

**Примечание:** Если поды `sentry-taskbroker-ingest-0` или `sentry-taskbroker-long-0` находятся в состоянии `CrashLoopBackOff` с ошибкой `UnknownTopicOrPartition`, создайте недостающие топики Kafka вручную:
```bash
kubectl -n sentry exec sentry-kafka-controller-0 -- kafka-topics.sh --bootstrap-server localhost:9092 --create --topic taskworker-ingest --partitions 1 --replication-factor 1
kubectl -n sentry exec sentry-kafka-controller-0 -- kafka-topics.sh --bootstrap-server localhost:9092 --create --topic taskworker-long --partitions 1 --replication-factor 1
kubectl -n sentry delete pod sentry-taskbroker-ingest-0 sentry-taskbroker-long-0
```

Доступ к веб-интерфейсу — через Ingress (hostname в `values-sentry-minimal.yaml`, по умолчанию `sentry.local`) или `kubectl port-forward`:

```bash
kubectl -n sentry port-forward svc/sentry-web 9000:9000
# Открыть http://localhost:9000, логин admin@sentry.local / admin
```

### Удаление

```bash
helm uninstall sentry -n sentry
kubectl delete -f clickhouse.yaml
kubectl delete namespace sentry
kubectl delete namespace clickhouse
# при необходимости: helm uninstall clickhouse-operator -n clickhouse-operator
kubectl delete namespace clickhouse-operator
```
