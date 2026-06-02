provider "yandex" {
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.default_zone
  token                    = var.yc_token
  service_account_key_file = var.yc_service_account_key_file
}

provider "github" {
  owner = var.github_owner
}
