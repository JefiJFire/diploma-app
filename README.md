# diploma-app

Тестовое приложение для дипломного проекта: nginx отдаёт статическую страницу с версией сборки.

## Структура репозиториев

| Репозиторий | Содержимое |
|---|---|
| `diploma-infra` | `terraform/bootstrap`, `terraform/infra`, `ansible/`, workflow Terraform |
| `diploma-k8s` | манифесты и values: kube-prometheus, ingress-nginx, Grafana, приложение |
| `diploma-app` (этот) | nginx-конфиг, статика, Dockerfile, workflow сборки и деплоя |

```
diploma-app/
├── Dockerfile         # nginx:1.28-alpine + конфиг + страница; версия через --build-arg APP_VERSION
├── nginx/default.conf # server на порту 80, проба /healthz
├── html/index.html    # страница, в неё при сборке подставляется версия
└── Makefile           # build, run, login, push
```

## Локальная проверка

```bash
make run                 # http://localhost:8080
curl localhost:8080/healthz      # ok
curl localhost:8080/version.txt  # версия сборки
```

Версия берётся из `git describe --tags --always --dirty`, либо задаётся явно: `make build VERSION=v1.0.0`.

## Публикация образа в Yandex Container Registry

Данные берутся из вывода `terraform/bootstrap`:

```bash
cd ../diploma-infra/terraform/bootstrap
terraform output -raw registry_id                                  # идентификатор реестра
mkdir -p ~/.config/yc
terraform output -raw ci_sa_key_json > ~/.config/yc/ci-sa-key.json # ключ сервисного аккаунта CI
chmod 600 ~/.config/yc/ci-sa-key.json
```

```bash
cd ../../../diploma-app
make push REGISTRY_ID=<id реестра> VERSION=v0.1.0
```

Образ будет доступен как `cr.yandex/<id реестра>/diploma-app:v0.1.0`. Скачивание образов в реестре открыто (роль `puller` для `allUsers`), поэтому кластеру секрет не нужен.

## CI/CD (GitHub Actions)

`.github/workflows/ci-cd.yml`:
- любой коммит: сборка образа, проверка (`/healthz` и версия на странице), push в реестр с тегом коротким SHA;
- git-тег `v*` (например, `git tag v1.0.0 && git push --tags`): сборка, push с этим тегом и деплой в кластер.

Секреты репозитория (Settings, Secrets and variables, Actions):

| Секрет | Откуда |
|---|---|
| `YC_REGISTRY_ID` | `terraform output -raw registry_id` (bootstrap) |
| `YC_CI_SA_KEY_JSON` | `terraform output -raw ci_sa_key_json` (bootstrap), роль только `images.pusher` |
| `KUBE_CONFIG` | `diploma-k8s/ci/make-kubeconfig.sh <IP мастера>` |
