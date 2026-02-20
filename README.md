# Развёртывание Sentry v29.2.0 в Yandex Cloud на Kubernetes. 

## Установка Sentry v29.2.0 (минимальный режим)

### 0. Подготовка (создать namespace и репозитории)

Выполните до шага 1.1 — оператор и Sentry устанавливаются в namespace `sentry`.

```bash
kubectl create namespace sentry
helm repo add altinity https://helm.altinity.com
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo update
```

### 1. ClickHouse (в v29 внешний ClickHouse обязателен)

По [документации Sentry](https://github.com/sentry-kubernetes/charts/blob/develop/charts/sentry/docs/external-clickhouse.md) используется внешний ClickHouse через [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator).

**1.1. Установка Altinity ClickHouse Operator** (ставим в namespace `sentry`, чтобы оператор наблюдал за CHI в том же namespace):

```bash
helm upgrade --install clickhouse-operator altinity/altinity-clickhouse-operator \
  --namespace sentry
```

**1.2. Создание ClickHouse (CHI)**:

```bash
kubectl apply -f clickhouse.yaml
kubectl -n sentry get clickhouseinstallation
kubectl -n sentry get pods -l clickhouse.altinity.com/chi=sentry-clickhouse
kubectl -n sentry wait --for=condition=ready pod -l clickhouse.altinity.com/chi=sentry-clickhouse --timeout=300s
kubectl -n sentry get svc -l clickhouse.altinity.com/chi=sentry-clickhouse
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
kubectl delete -f clickhouse.yaml
kubectl delete namespace sentry
# при необходимости: helm uninstall clickhouse-operator -n sentry
```
