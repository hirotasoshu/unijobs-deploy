resource "yandex_iam_service_account" "api_gateway" {
  name        = "${local.project}-api-gateway"
  description = "Runtime service account for API Gateway."
}

resource "yandex_iam_service_account" "backend" {
  name        = "${local.project}-backend"
  description = "Runtime service account for UniJobs backend serverless container."
}

resource "yandex_resourcemanager_folder_iam_member" "api_gateway_container_invoker" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "serverless.containers.invoker"
  member    = "serviceAccount:${yandex_iam_service_account.api_gateway.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "backend_ydb_editor" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "ydb.editor"
  member    = "serviceAccount:${yandex_iam_service_account.backend.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "backend_logging_writer" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.backend.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "backend_lockbox_payload_viewer" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "lockbox.payloadViewer"
  member    = "serviceAccount:${yandex_iam_service_account.backend.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "backend_registry_puller" {
  folder_id = data.yandex_client_config.current.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.backend.id}"
}

resource "yandex_storage_bucket_iam_binding" "api_gateway_read_ui" {
  bucket = yandex_storage_bucket.ui.bucket
  role   = "storage.viewer"

  members = [
    "serviceAccount:${yandex_iam_service_account.api_gateway.id}",
  ]
}
