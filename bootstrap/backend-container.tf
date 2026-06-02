resource "yandex_serverless_container" "backend" {
  name               = "${local.project}-backend"
  memory             = 512
  cores              = 1
  core_fraction      = 50
  execution_timeout  = "30s"
  service_account_id = yandex_iam_service_account.backend.id

  log_options {
    log_group_id = yandex_logging_group.main.id
  }

  image {
    url     = local.initial_backend_image_url
    command = var.backend_image_url == null ? ["/whoami"] : null
    args    = var.backend_image_url == null ? ["-port", "8080"] : null

    environment = {
      APP_ENV            = "production"
      DATABASE_BACKEND   = "ydb"
      YDB_ENDPOINT       = "grpcs://${yandex_ydb_database_serverless.unijobs.ydb_api_endpoint}/?database=${yandex_ydb_database_serverless.unijobs.database_path}"
      YDB_AUTH_MODE      = "metadata"
      AUTH_JWT_SECRET    = random_password.auth_jwt_secret.result
      AUTH_JWT_ISSUER    = "unijobs"
      CORS_ALLOW_ORIGINS = "*"
    }
  }

  depends_on = [
    null_resource.bootstrap_backend_image,
    yandex_resourcemanager_folder_iam_member.backend_registry_puller,
  ]
}

resource "yandex_serverless_container_iam_binding" "backend_invoker" {
  container_id = yandex_serverless_container.backend.id
  role         = "serverless.containers.invoker"

  members = [
    "serviceAccount:${yandex_iam_service_account.api_gateway.id}",
  ]
}
