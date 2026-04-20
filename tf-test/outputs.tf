output "bigquery_dataset_id" {
  value       = google_bigquery_dataset.trivy_logs.dataset_id
  description = "The ID of the BigQuery dataset where Trivy logs are exported."
}

output "bigquery_table_id" {
  value       = google_bigquery_table.trivy_vulnerabilities_clean.table_id
  description = "The ID of the table for processed vulnerability reports."
}

output "bigquery_table_full_path" {
  value       = "${google_bigquery_dataset.trivy_logs.project}.${google_bigquery_dataset.trivy_logs.dataset_id}.${google_bigquery_table.trivy_vulnerabilities_clean.table_id}"
  description = "The full dot-separated path of the BigQuery table for use in Python scripts."
}

output "gke_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "The name of the GKE cluster."
}
