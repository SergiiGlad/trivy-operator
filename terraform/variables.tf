variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "dynamic-link-1ca0e"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-c"
}

variable "create_github_repo" {
  type    = bool
  default = false
}
