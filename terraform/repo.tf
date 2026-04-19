resource "github_repository" "trivy_operator" {
  count = var.create_github_repo ? 1 : 0  
  name        = "trivy-operator"
  description = "Infrastructure and automation for Trivy Operator on GKE with BigQuery log synchronization."
  visibility  = "public"
}

