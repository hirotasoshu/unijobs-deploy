resource "yandex_lockbox_secret" "backend" {
  name        = "${local.project}-backend-secrets"
  description = "Runtime secrets and deployment configuration for UniJobs backend."
  labels      = local.labels
}

resource "yandex_lockbox_secret_version" "backend" {
  secret_id = yandex_lockbox_secret.backend.id

  entries {
    key        = "AUTH_JWT_SECRET"
    text_value = random_password.auth_jwt_secret.result
  }

  entries {
    key        = "YDB_ENDPOINT"
    text_value = "grpcs://${yandex_ydb_database_serverless.unijobs.ydb_api_endpoint}/?database=${yandex_ydb_database_serverless.unijobs.database_path}"
  }
}

resource "random_password" "auth_jwt_secret" {
  length  = 48
  special = true
}
