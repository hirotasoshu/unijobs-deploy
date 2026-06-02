locals {
  project = var.project

  labels = {
    project = var.project
    course  = "virtualization-final"
  }

  ui_bucket_name    = "${var.project}-ui-${data.yandex_client_config.current.folder_id}"
  state_bucket_name = "${var.project}-tfstate-${data.yandex_client_config.current.folder_id}"
}

data "yandex_client_config" "current" {}

resource "yandex_container_registry" "main" {
  name   = "${var.project}-registry"
  labels = local.labels
}

resource "yandex_iam_service_account" "ci" {
  name        = "${var.project}-ci"
  description = "CI service account for pushing backend images and uploading UI files."
}

resource "yandex_resourcemanager_folder_iam_member" "ci_registry_pusher" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_serverless_editor" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "serverless.containers.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_service_account_user" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "iam.serviceAccounts.user"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_ydb_editor" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "ydb.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_functions_editor" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "functions.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_lockbox_payload_viewer" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "lockbox.payloadViewer"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_lockbox_viewer" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "lockbox.viewer"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_logging_editor" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "logging.editor"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ci_storage_editor" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.ci.id}"
}

resource "yandex_iam_service_account_static_access_key" "ci_storage" {
  service_account_id = yandex_iam_service_account.ci.id
  description        = "S3-compatible static key for UI uploads from CI."
}

resource "yandex_iam_service_account_key" "ci" {
  service_account_id = yandex_iam_service_account.ci.id
  description        = "Authorized key for GitHub Actions YCR login."
  key_algorithm      = "RSA_4096"
}

resource "yandex_storage_bucket" "ui" {
  bucket     = local.ui_bucket_name
  access_key = yandex_iam_service_account_static_access_key.ci_storage.access_key
  secret_key = yandex_iam_service_account_static_access_key.ci_storage.secret_key
  max_size   = 1073741824

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  anonymous_access_flags {
    read = false
    list = false
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.ci_storage_editor,
  ]

}

resource "yandex_storage_bucket" "terraform_state" {
  bucket     = local.state_bucket_name
  access_key = yandex_iam_service_account_static_access_key.ci_storage.access_key
  secret_key = yandex_iam_service_account_static_access_key.ci_storage.secret_key
  max_size   = 1073741824

  versioning {
    enabled = true
  }

  anonymous_access_flags {
    read = false
    list = false
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.ci_storage_editor,
  ]
}

resource "yandex_storage_bucket_iam_binding" "ci_storage_editor" {
  bucket = yandex_storage_bucket.ui.bucket
  role   = "storage.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.ci.id}",
  ]
}

resource "yandex_storage_bucket_iam_binding" "ci_state_editor" {
  bucket = yandex_storage_bucket.terraform_state.bucket
  role   = "storage.editor"

  members = [
    "serviceAccount:${yandex_iam_service_account.ci.id}",
  ]
}
