variable "default_zone" {
  description = "Default availability zone."
  type        = string
  default     = "ru-central1-a"
}

variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "unijobs"
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID used by the Terraform provider. Prefer TF_VAR_yc_cloud_id instead of terraform.tfvars."
  type        = string
  default     = null
}

variable "yc_folder_id" {
  description = "Yandex Cloud folder ID used by the Terraform provider. Prefer TF_VAR_yc_folder_id instead of terraform.tfvars."
  type        = string
  default     = null
}

variable "yc_token" {
  description = "Optional IAM/OAuth token for local Terraform runs. Prefer TF_VAR_yc_token and do not commit it."
  type        = string
  default     = null
  sensitive   = true
}

variable "yc_service_account_key_file" {
  description = "Optional path to a Yandex Cloud service account JSON key for local Terraform runs. Prefer TF_VAR_yc_service_account_key_file and do not commit it."
  type        = string
  default     = null
  sensitive   = true
}

variable "backend_image_url" {
  description = "Optional initial image URL for the bootstrap Serverless Container revision. If omitted, Terraform pushes bootstrap_backend_image_source to YCR and uses it."
  type        = string
  default     = null
}

variable "bootstrap_backend_image_source" {
  description = "Public Docker image used as the initial placeholder backend revision. Terraform retags and pushes it into the created YCR registry."
  type        = string
  default     = "traefik/whoami:latest"
}

variable "github_owner" {
  description = "GitHub user or organization that owns UniJobs repositories. Used for Workload Identity Federation audience and subjects."
  type        = string
}

variable "github_backend_repo" {
  description = "GitHub repository name for backend deployments."
  type        = string
  default     = "unijobs-backend"
}

variable "github_frontend_repo" {
  description = "GitHub repository name for frontend deployments."
  type        = string
  default     = "unijobs-ui"
}

variable "github_deploy_environment" {
  description = "GitHub Environment name used by deploy workflows. It becomes part of the OIDC subject."
  type        = string
  default     = "production"
}
