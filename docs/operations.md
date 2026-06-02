# Эксплуатация UniJobs Deployment

## Предварительные требования

- Yandex Cloud CLI авторизован локально через `yc init`.
- Для Terraform в локальном ignored `terraform.tfvars` заданы стабильные `yc_cloud_id`, `yc_folder_id`, `github_owner`, а перед запуском экспортирован short-lived `TF_VAR_yc_token` или путь к service account key file.
- Terraform установлен.
- Docker установлен.
- `gh` авторизован, а `GITHUB_TOKEN` указывает на токен с доступом к backend/frontend репозиториям.
- Docker настроен для push в Yandex Container Registry после создания registry: `yc container registry configure-docker`.
- GitHub Environment `production` создавать вручную не нужно: Terraform создает его сам.

`terraform.tfvars` хранится только локально и игнорируется Git. Его удобно использовать для стабильных значений, которые не протухают:

```hcl
default_zone = "ru-central1-a"
project      = "unijobs"
github_owner = "hirotasoshu"

yc_cloud_id  = "b1gp6d711skigtbd4ueo"
yc_folder_id = "b1gls2borktlo05v2fvs"
```

Минимальный набор env vars перед локальным запуском Terraform:

```bash
export TF_VAR_yc_token="$(yc iam create-token)"
export GITHUB_TOKEN="$(gh auth token)"
```

`yc_token` лучше не класть в `terraform.tfvars`: это секрет и short-lived значение, которое быстро протухает. `GITHUB_TOKEN` тоже лучше держать в окружении, потому что GitHub provider стандартно читает его из env.

Если Terraform запускается от отдельного service account, вместо `TF_VAR_yc_token` используйте `TF_VAR_yc_service_account_key_file` с путем к JSON key-файлу. `YC_SERVICE_ACCOUNT_KEY_FILE` напрямую не используется: provider читает именно input variable `yc_service_account_key_file`.

## Применение инфраструктуры

```bash
cd unijobs-deploy/bootstrap
cp terraform.tfvars.example terraform.tfvars
```

Заполните `github_owner`, `yc_cloud_id`, `yc_folder_id`, затем выполните:

```bash
terraform init
terraform apply -target=yandex_container_registry.main
yc container registry configure-docker
terraform apply
```

Во время первого apply Terraform создаст YCR, локально запушит placeholder image `traefik/whoami:latest` в этот registry и создаст Serverless Container с этим image. Первый backend release заменит placeholder на настоящий backend image.

Важно: не запускайте полный первый `terraform apply` до `yc container registry configure-docker`, если `backend_image_url` не задан. Terraform должен локально запушить placeholder image в только что созданный registry.

Публичный URL приложения:

```bash
terraform output -raw app_url
```

## Настройка GitHub Variables

Deploy workflows используют keyless IAM через GitHub OIDC. JSON key service account в GitHub не нужен.

Terraform создает GitHub Environment `production` и Actions environment variables сам. Значения ниже нужны только для ручной проверки результата, руками заводить их обычно не требуется.

Backend repository variables:

```bash
terraform output -raw ci_service_account_id        # YC_SA_ID
terraform output -raw folder_id                    # YC_FOLDER_ID
terraform output -raw registry_id                  # YC_REGISTRY_ID
terraform output -raw backend_container_name       # YC_BACKEND_CONTAINER_NAME
terraform output -raw backend_service_account_id   # YC_BACKEND_SERVICE_ACCOUNT_ID
terraform output -raw backend_lockbox_secret_id    # YC_BACKEND_LOCKBOX_SECRET_ID
terraform output -raw log_group_id                 # YC_LOG_GROUP_ID
terraform output -raw app_url                      # APP_URL
```

Frontend repository variables:

```bash
terraform output -raw ci_service_account_id        # YC_SA_ID
terraform output -raw folder_id                    # YC_FOLDER_ID
terraform output -raw ui_bucket                    # YC_UI_BUCKET
terraform output -raw app_url                      # APP_URL
```

Важно: deploy jobs используют `environment: production`. Terraform создает federated credentials под OIDC subject вида:

```text
repo:<github_owner>/<repo>:environment:production
```

Если поменять имя GitHub Environment, нужно поменять `github_deploy_environment` в Terraform и выполнить `terraform apply`.

`yc-actions/yc-iam-token-fed@1.0.0` сам запрашивает GitHub OIDC token с audience `https://github.com/<github_owner>`. Поэтому Terraform WIF federation настроена с таким же audience, а workflow передает только `yc-sa-id`.

## Backend CI и release gate

Backend CI запускается на:

- `push` в `main`
- `pull_request` в `main`
- `push` любого tag

Backend release deploy запускается на published GitHub Release. При создании release из GitHub UI workflow:

1. Checkout release tag.
2. Проверяет, что release является latest.
3. Определяет SHA release tag.
4. Ждет успешный `Backend CI` workflow run для этого SHA и события `push`.
5. Если CI успешен, продолжает deploy.
6. Если CI failed/cancelled/timed out или не появился за 30 минут, deploy останавливается.

Рекомендуемый порядок backend release:

1. Создать annotated или lightweight tag в `unijobs-backend`.
2. Запушить tag в GitHub, чтобы стартовал `Backend CI` по событию `push` tag.
3. Дождаться успешного `Backend CI` для этого tag.
4. Опубликовать GitHub Release из этого tag, не draft и не prerelease.

Если release опубликовать сразу после push tag, deploy workflow будет ждать CI до 30 минут. Если release создать так, что GitHub сам создаст tag без отдельного tag push, backend deploy может не найти `Backend CI` run и остановиться по timeout.

## Backend deploy

Backend deploy выполняет:

1. Получение IAM token через `yc-actions/yc-iam-token-fed`.
2. Чтение `YDB_ENDPOINT` из Lockbox напрямую через Lockbox Payload API; значение содержит полный YDB DSN вида `grpcs://host:2135/?database=/...`.
3. Логин в YCR через `yc-actions/yc-cr-login`.
4. Build/push image `cr.yandex/<registry-id>/unijobs-backend:<release-tag>`.
5. `alembic upgrade head` с `YDB_AUTH_MODE=access_token`.
6. Deploy Serverless Container через `yc-actions/yc-sls-container-deploy`.
7. Smoke test `GET /api/healthz`.

`yc-actions/yc-lockbox` намеренно не используется: его `action.yml` требует `yc-sa-json-credentials` и не принимает IAM token. Чтобы не хранить long-lived JSON key в GitHub, workflow читает Lockbox через API с short-lived IAM token.

## Frontend deploy

Frontend deploy выполняет:

1. Checkout release tag.
2. Проверку latest release.
3. Получение IAM token через `yc-actions/yc-iam-token-fed`.
4. `npm ci` и `npm run build`.
5. Upload immutable static release в `releases/<release-tag>/` через `yc-actions/yc-obj-storage-upload`.
6. Upload/promote static files в `current/` через `yc-actions/yc-obj-storage-upload`.
7. Smoke test public `APP_URL`.

Frontend tests не добавляются.

Frontend release создается отдельно в репозитории `unijobs-ui`. Для frontend нет CI gate: published release сразу запускает build/upload/promote static files.

## Проверка после деплоя

```bash
curl "$(terraform output -raw app_url)/api/healthz"
```

Затем откройте `app_url`, зарегистрируйте пользователя, создайте отклик на вакансию, обновите cover letter, удалите отклик и убедитесь, что он исчез из списка.

## Monitoring и Logging

Terraform создает:

- `yandex_logging_group.main` с retention `168h`.
- `yandex_monitoring_dashboard.main` с секциями API Gateway, Serverless Backend, Serverless YDB и Object Storage.
- `log_options` у Serverless Container и API Gateway, чтобы runtime/API Gateway logs попадали в общий log group.

После `terraform apply` dashboard можно найти в Yandex Monitoring по имени `unijobs-dashboard` или через Terraform resource `yandex_monitoring_dashboard.main`.

Что смотреть при проверке:

- API Gateway: request rate, error rate, `/api` request rate и p95 latency.
- Serverless Container: starts/sec, errors/sec, p95 execution time, p95 memory, cold starts/sec и inflight requests.
- Serverless YDB: consumed request units, completed requests/sec, p95 API latency и storage used.
- Object Storage: UI bucket space usage и object count.
- Cloud Logging group `unijobs-logs`: API Gateway и Serverless Container execution/runtime logs.

Traces намеренно не настраиваются.

Как добавить новые графики:

1. Найти metric name в справочнике метрик нужного Yandex Cloud сервиса.
2. Добавить новый `widgets { chart { ... queries { target { query = "..." }}}}` в `bootstrap/monitoring.tf`.
3. Отфильтровать query по `service`, `folderId` и resource label (`container`, bucket/database/gateway id), если сервис требует resource label.
4. Выполнить `terraform fmt -recursive && terraform validate && terraform apply`.

Для alerting можно дополнительно завести trigger/alert policy в Yandex Monitoring на error rate контейнера и p95 latency, но текущий учебный стенд ограничивается dashboard + Cloud Logging.

## Rollback

Database rollback не автоматизирован. Для обычного rollback не запускайте Alembic downgrade автоматически; используйте forward-compatible migrations.

Backend rollback: опубликовать исправляющий release или вручную redeploy предыдущего image tag.

Frontend rollback: повторно загрузить нужный static release в `current/` или опубликовать исправляющий release.
