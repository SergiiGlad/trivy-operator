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

resource "google_cloudbuild_trigger" "trivy_operator_pr_trigger" {
  location        = var.region
  name            = "trivy-operator-pr"
  project         = var.project_id
  service_account = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  filename        = "cloudbuild.yaml"

  substitutions = {
    _PROJECT_ID                 = var.project_id
    _REGION                     = var.region
    _GITHUB_APP_INSTALLATION_ID = tostring(var.github_app_installation_id)
  }

  repository_event_config {
    repository = google_cloudbuildv2_repository.trivy_repo.id
    pull_request {
      branch = "^main$"
    }
  }
}

# Trigger that runs on every Push to the main branch
resource "google_cloudbuild_trigger" "trivy_operator_push_main_trigger" {
  location        = var.region
  name            = "trivy-operator-push-main"
  project         = var.project_id
  service_account = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  filename        = "cloudbuild.yaml"

  substitutions = {
    _PROJECT_ID                 = var.project_id
    _REGION                     = var.region
    _GITHUB_APP_INSTALLATION_ID = tostring(var.github_app_installation_id)
  }

  repository_event_config {
    repository = google_cloudbuildv2_repository.trivy_repo.id
    push {
      branch = "^main$"
    }
  }
}
