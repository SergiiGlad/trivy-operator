terraform {
  backend "gcs" {
    bucket         = "dynamic-link-1ca0e-terraform-state"
    encryption_key = null
    prefix         = "dev/trivy"
  }
}
