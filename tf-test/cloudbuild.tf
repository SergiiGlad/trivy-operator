data "google_project" "project" {}

# Secret to store the GitHub PAT
resource "google_secret_manager_secret" "github_token" {
  secret_id = "github-token"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "github_token_version" {
  secret      = google_secret_manager_secret.github_token.id
  secret_data = var.github_pat
}

# Grant Cloud Build Service Agent access to the secret
resource "google_secret_manager_secret_iam_member" "cloudbuild_secret_accessor" {
  secret_id = google_secret_manager_secret.github_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Connection between Google Cloud and GitHub (2nd Generation)
resource "google_cloudbuildv2_connection" "github_conn" {
  location = var.region
  name     = "github-connection"

  github_config {
    # This ID is found in your GitHub App settings after installation
    app_installation_id = var.github_app_installation_id

    # Ensure the PAT used in this secret has the scopes mentioned above
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github_token_version.id
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.cloudbuild_secret_accessor]
}

# Linking the specific repository to the connection
resource "google_cloudbuildv2_repository" "trivy_repo" {
  location          = var.region
  name              = "trivy-operator"
  parent_connection = google_cloudbuildv2_connection.github_conn.id
  remote_uri        = github_repository.trivy_operator.http_clone_url 
}

resource "google_cloudbuild_trigger" "trivy-operator-pr-trigger" {
  description        = null
  disabled           = false
  filename           = "cloudbuild.yaml"
  filter             = null
  ignored_files      = []
  include_build_logs = null
  included_files     = []
  location           = "us-central1"
  name               = "trivy-operator-pr"
  project            = "dynamic-link-1ca0e"
  service_account    = "projects/dynamic-link-1ca0e/serviceAccounts/185294977314-compute@developer.gserviceaccount.com"
  substitutions      = {}
  tags               = []
  approval_config {
    approval_required = false
  }
  repository_event_config {
    repository = "projects/dynamic-link-1ca0e/locations/us-central1/connections/github-connection/repositories/trivy-operator"
    pull_request {
      branch          = "main"
      comment_control = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
      invert_regex    = false
    }
  }
}
