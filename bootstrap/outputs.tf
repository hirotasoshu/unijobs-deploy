output "registry_id" {
  value = yandex_container_registry.main.id
}

output "backend_image_prefix" {
  value = "cr.yandex/${yandex_container_registry.main.id}/unijobs-backend"
}

output "ui_bucket" {
  value = yandex_storage_bucket.ui.bucket
}

output "terraform_state_bucket" {
  value = yandex_storage_bucket.terraform_state.bucket
}

output "app_url" {
  value = "https://${yandex_api_gateway.app.domain}"
}

output "api_gateway_domain" {
  value = yandex_api_gateway.app.domain
}

output "log_group_id" {
  value = yandex_logging_group.main.id
}

output "backend_container_id" {
  value = yandex_serverless_container.backend.id
}

output "backend_container_name" {
  value = yandex_serverless_container.backend.name
}

output "backend_service_account_id" {
  value = yandex_iam_service_account.backend.id
}

output "auth_jwt_secret" {
  value     = random_password.auth_jwt_secret.result
  sensitive = true
}

output "backend_lockbox_secret_id" {
  value = yandex_lockbox_secret.backend.id
}

output "ydb_endpoint" {
  value = "grpcs://${yandex_ydb_database_serverless.unijobs.ydb_api_endpoint}/?database=${yandex_ydb_database_serverless.unijobs.database_path}"
}

output "ci_service_account_id" {
  value = yandex_iam_service_account.ci.id
}

output "folder_id" {
  value = data.yandex_client_config.current.folder_id
}

output "github_wif_audience" {
  value = local.github_oidc_audience
}

output "ci_storage_access_key" {
  value     = yandex_iam_service_account_static_access_key.ci_storage.access_key
  sensitive = true
}

output "ci_storage_secret_key" {
  value     = yandex_iam_service_account_static_access_key.ci_storage.secret_key
  sensitive = true
}

output "ci_service_account_key_json" {
  value = jsonencode({
    id                 = yandex_iam_service_account_key.ci.id
    service_account_id = yandex_iam_service_account_key.ci.service_account_id
    created_at         = yandex_iam_service_account_key.ci.created_at
    key_algorithm      = yandex_iam_service_account_key.ci.key_algorithm
    public_key         = yandex_iam_service_account_key.ci.public_key
    private_key        = yandex_iam_service_account_key.ci.private_key
  })
  sensitive = true
}
