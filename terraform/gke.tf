resource "google_container_cluster" "primary" {
  name     = "trivy-gke-cluster"
  location = var.zone

  # Best practice: remove default node pool and use a separate google_container_node_pool resource.
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"

    # Standard OAuth scopes for GKE nodes; access is managed via IAM roles.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
