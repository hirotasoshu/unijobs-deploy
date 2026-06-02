resource "yandex_ydb_database_serverless" "unijobs" {
  name                = "${local.project}-ydb"
  deletion_protection = false

  serverless_database {
    storage_size_limit = 5
  }

  labels = local.labels
}
