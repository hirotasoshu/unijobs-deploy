# unijobs-deploy

Terraform-стенд для production-like деплоя UniJobs в Yandex Cloud.

## Архитектура

```text
Yandex API Gateway generated HTTPS domain
  -> Object Storage bucket: frontend static files under current/
  -> /api/* -> Serverless Container: unijobs-backend
      -> Serverless YDB
      -> Yandex Lockbox для runtime secrets
```

Production-стенд работает без виртуальных машин: frontend хранится в Object Storage, backend запускается в Serverless Containers, база данных — Serverless YDB. API Gateway является публичной serverless-точкой входа: он принимает HTTPS-трафик, маршрутизирует static/API paths и передает `/api/*` в Serverless Container. Поэтому критерии про ВМ/контейнерный кластер БД/балансировщик из задания закрываются serverless-only исключением, а роль L7 routing/load balancing выполняет API Gateway.

Аутентификация реализована в `unijobs-backend`: пользователь регистрируется или логинится по email/password, backend выпускает JWT access token, защищенные запросы используют `Authorization: Bearer <token>`.

## Что создает `bootstrap/`

- Yandex Container Registry для backend images.
- Object Storage bucket для frontend releases.
- Object Storage bucket для Terraform state backups.
- CI service account для GitHub Actions.
- GitHub Workload Identity Federation для keyless IAM auth из GitHub Actions.
- GitHub Environment `production` и Actions environment variables для backend/frontend deploy workflows.
- Lockbox secret для backend runtime secrets/config.
- Serverless YDB.
- Serverless Container для backend.
- API Gateway для static UI и `/api/*`.
- Cloud Logging и Monitoring dashboard.

## Документация

- `docs/operations.md` — единственная подробная инструкция по bootstrap, GitHub variables, release deploy, проверке после деплоя, monitoring/logging и rollback.
- `docs/cost-estimate.md` — оценка стоимости serverless-стенда.

## Короткий Deploy Flow

1. Применить инфраструктуру из `bootstrap/` по инструкции в `docs/operations.md`.
2. Убедиться, что Terraform создал GitHub Environment `production` и Actions variables для backend/frontend репозиториев.
3. Опубликовать backend/frontend GitHub Release из нужного tag.
4. Backend deploy дождется успешного `Backend CI` для release tag, затем соберет image, выполнит Alembic migrations и обновит Serverless Container.
5. Frontend deploy соберет static bundle, загрузит immutable release в Object Storage и промоутнет его в `current/`.

GitHub deploy использует keyless auth через GitHub OIDC и `yc-actions/yc-iam-token-fed`. JSON key service account в GitHub не нужен.
