locals {
  github_common_environment_variables = {
    YC_SA_ID     = yandex_iam_service_account.ci.id
    YC_FOLDER_ID = data.yandex_client_config.current.folder_id
    APP_URL      = "https://${yandex_api_gateway.app.domain}"
  }

  github_backend_environment_variables = merge(
    local.github_common_environment_variables,
    {
      YC_REGISTRY_ID                = yandex_container_registry.main.id
      YC_BACKEND_CONTAINER_NAME     = yandex_serverless_container.backend.name
      YC_BACKEND_SERVICE_ACCOUNT_ID = yandex_iam_service_account.backend.id
      YC_BACKEND_LOCKBOX_SECRET_ID  = yandex_lockbox_secret.backend.id
      YC_LOG_GROUP_ID               = yandex_logging_group.main.id
    }
  )

  github_frontend_environment_variables = merge(
    local.github_common_environment_variables,
    {
      YC_UI_BUCKET = yandex_storage_bucket.ui.bucket
    }
  )
}

resource "github_repository_environment" "backend_deploy" {
  repository  = var.github_backend_repo
  environment = var.github_deploy_environment
}

resource "github_repository_environment" "frontend_deploy" {
  repository  = var.github_frontend_repo
  environment = var.github_deploy_environment
}

resource "github_actions_environment_variable" "backend" {
  for_each = local.github_backend_environment_variables

  repository    = var.github_backend_repo
  environment   = github_repository_environment.backend_deploy.environment
  variable_name = each.key
  value         = each.value
}

resource "github_actions_environment_variable" "frontend" {
  for_each = local.github_frontend_environment_variables

  repository    = var.github_frontend_repo
  environment   = github_repository_environment.frontend_deploy.environment
  variable_name = each.key
  value         = each.value
}
