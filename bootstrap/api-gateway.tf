resource "yandex_api_gateway" "app" {
  name   = "${local.project}-app-gateway"
  labels = local.labels

  log_options {
    log_group_id = yandex_logging_group.main.id
    min_level    = "INFO"
  }

  spec = <<-YAML
openapi: 3.0.0
info:
  title: UniJobs App Gateway
  version: 1.0.0
paths:
  /api/{proxy+}:
    x-yc-apigateway-any-method:
      parameters:
        - name: proxy
          in: path
          required: false
          schema:
            type: string
      x-yc-apigateway-integration:
        type: serverless_containers
        container_id: ${yandex_serverless_container.backend.id}
        service_account_id: ${yandex_iam_service_account.api_gateway.id}
  /assets/{file+}:
    get:
      parameters:
        - name: file
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${yandex_storage_bucket.ui.bucket}
        object: current/assets/{file}
        service_account_id: ${yandex_iam_service_account.api_gateway.id}
  /:
    get:
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${yandex_storage_bucket.ui.bucket}
        object: current/index.html
        service_account_id: ${yandex_iam_service_account.api_gateway.id}
  /{file}:
    get:
      parameters:
        - name: file
          in: path
          required: true
          schema:
            type: string
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${yandex_storage_bucket.ui.bucket}
        object: current/{file}
        service_account_id: ${yandex_iam_service_account.api_gateway.id}
  /{proxy+}:
    get:
      parameters:
        - name: proxy
          in: path
          required: false
          schema:
            type: string
      x-yc-apigateway-integration:
        type: object_storage
        bucket: ${yandex_storage_bucket.ui.bucket}
        object: current/index.html
        service_account_id: ${yandex_iam_service_account.api_gateway.id}
YAML

  depends_on = [
    yandex_storage_bucket_iam_binding.api_gateway_read_ui,
    yandex_serverless_container_iam_binding.backend_invoker,
  ]
}
