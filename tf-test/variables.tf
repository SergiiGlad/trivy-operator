variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "create_github_repo" {
  type    = bool
  default = false
}

variable "github_app_installation_id" {
  description = "The installation ID of the Google Cloud Build GitHub App"
  type        = number
}

variable "github_pat" {
  description = "The Personal Access Token for GitHub"
  type        = string
}
