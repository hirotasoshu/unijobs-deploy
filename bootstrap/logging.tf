resource "yandex_logging_group" "main" {
  name             = "${local.project}-logs"
  folder_id        = data.yandex_client_config.current.folder_id
  retention_period = "168h"
  labels           = local.labels
}
