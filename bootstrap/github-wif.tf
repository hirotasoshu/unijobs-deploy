locals {
  github_oidc_audience = "https://github.com/${var.github_owner}"

  github_backend_subject  = "repo:${var.github_owner}/${var.github_backend_repo}:environment:${var.github_deploy_environment}"
  github_frontend_subject = "repo:${var.github_owner}/${var.github_frontend_repo}:environment:${var.github_deploy_environment}"
}

resource "yandex_iam_workload_identity_oidc_federation" "github" {
  name        = "${local.project}-github"
  folder_id   = data.yandex_client_config.current.folder_id
  description = "GitHub Actions OIDC federation for UniJobs deploy workflows."
  disabled    = false
  audiences   = [local.github_oidc_audience]
  issuer      = "https://token.actions.githubusercontent.com"
  jwks_url    = "https://token.actions.githubusercontent.com/.well-known/jwks"
  labels      = local.labels
}

resource "yandex_iam_workload_identity_federated_credential" "github_backend" {
  service_account_id  = yandex_iam_service_account.ci.id
  federation_id       = yandex_iam_workload_identity_oidc_federation.github.id
  external_subject_id = local.github_backend_subject
}

resource "yandex_iam_workload_identity_federated_credential" "github_frontend" {
  service_account_id  = yandex_iam_service_account.ci.id
  federation_id       = yandex_iam_workload_identity_oidc_federation.github.id
  external_subject_id = local.github_frontend_subject
}
