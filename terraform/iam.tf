locals {
  # This matches the service account defined in your cloudbuild_trigger resources
  build_sa_email = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  cloudbuild_roles = [
    "roles/bigquery.admin",                  # Required for BQ Dataset, Table, and Dataset IAM management
    "roles/compute.admin",                   # Required for managing GKE-related compute resources (vPC, instances)
    "roles/container.admin",                 # Required for GKE Cluster and Node Pool management
    "roles/iam.serviceAccountUser",          # Required to pass the service account to GKE nodes
    "roles/logging.configWriter",            # Required for creating Logging Sinks
    "roles/resourcemanager.projectIamAdmin", # Required to manage project-level IAM (like the log sink writer)
    "roles/secretmanager.admin",             # Required to manage secrets and versions
    "roles/storage.admin",                   # Required for GCS buckets (Terraform state or logs)
  ]
}

resource "google_project_iam_member" "cloudbuild_sa_permissions" {
  for_each = toset(local.cloudbuild_roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${local.build_sa_email}"

  depends_on = [data.google_project.project]
}
