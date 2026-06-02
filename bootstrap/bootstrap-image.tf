locals {
  bootstrap_backend_image_url = "cr.yandex/${yandex_container_registry.main.id}/unijobs-backend-bootstrap:latest"
  initial_backend_image_url   = coalesce(var.backend_image_url, local.bootstrap_backend_image_url)
}

resource "null_resource" "bootstrap_backend_image" {
  count = var.backend_image_url == null ? 1 : 0

  triggers = {
    source_image = var.bootstrap_backend_image_source
    target_image = local.bootstrap_backend_image_url
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -euo pipefail
      docker pull "${var.bootstrap_backend_image_source}"
      docker tag "${var.bootstrap_backend_image_source}" "${local.bootstrap_backend_image_url}"
      docker push "${local.bootstrap_backend_image_url}"
    BASH
  }

  depends_on = [
    yandex_container_registry.main,
    yandex_resourcemanager_folder_iam_member.ci_registry_pusher,
  ]
}
