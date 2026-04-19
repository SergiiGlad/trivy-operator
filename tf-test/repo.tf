resource "github_repository" "trivy_operator" {
  name        = "trivy-operator"
  description = "Infrastructure and automation for Trivy Operator on GKE with BigQuery log synchronization."
  visibility  = "public"
}

