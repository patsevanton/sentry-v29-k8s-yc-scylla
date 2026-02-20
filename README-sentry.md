# Установка Sentry

### 2. Репозиторий Sentry

Репозиторий и namespace уже созданы в шаге 0. При необходимости повторите:

```bash
kubectl create namespace sentry
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo add sentry https://sentry-kubernetes.github.io/charts
helm repo update
```

### 3. Установка Sentry

```bash
helm install sentry sentry/sentry --version 29.3.0 -n sentry \
  -f values-sentry-minimal.yaml --timeout=900s
```

Без `--wait` установка не будет ждать готовности всех подов; после установки проверьте состояние и логи (шаг 5). При необходимости обновление:

```bash
helm upgrade sentry sentry/sentry --version 29.3.0 -n sentry \
  -f values-sentry-minimal.yaml --timeout=600s
```

### 4. Проверка подов и логов

```bash
kubectl -n sentry get pods
kubectl -n sentry logs deployment/sentry-snuba-api --tail=20
kubectl -n sentry logs sentry-taskbroker-ingest-0 --tail=20
kubectl -n sentry logs deployment/sentry-web --tail=20
```
