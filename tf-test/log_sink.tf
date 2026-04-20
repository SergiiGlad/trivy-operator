resource "google_logging_project_sink" "trivy_logs" {
  name        = "trivy_logs"
  description = "Export trivy-operator logs to BigQuery"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.trivy_logs.dataset_id}"

  # Filter based on the requirements in bq.txt
  filter = <<EOT
resource.type="k8s_container"
resource.labels.project_id="${var.project_id}"
resource.labels.location="${var.zone}"
resource.labels.cluster_name="${google_container_cluster.primary.name}"
resource.labels.namespace_name="trivy-system"
resource.labels.pod_name=~"scan-vulnerabilityreport-.*"
severity>=DEFAULT
EOT

  unique_writer_identity = true
}

resource "google_bigquery_dataset_iam_member" "log_sink_writer" {
  dataset_id = google_bigquery_dataset.trivy_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.trivy_logs.writer_identity
}
