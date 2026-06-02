terraform {
  required_version = ">= 1.6.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }

    github = {
      source  = "integrations/github"
      version = ">= 6.4.0"
    }
  }
}
