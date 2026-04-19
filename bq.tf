resource "google_bigquery_dataset" "trivy_logs" {
  dataset_id                 = "bq_trivy_logs_flows"
  friendly_name              = "Trivy Operator Logs"
  description                = "Logs exported from the trivy-system namespace in GKE"
  location                   = var.region
  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "trivy_vulnerabilities_clean" {
  dataset_id          = google_bigquery_dataset.trivy_logs.dataset_id
  table_id            = "trivy_vulnerabilities_clean"
  deletion_protection = false

  description = "Table for storing decompressed and processed Trivy vulnerability reports"

  # Time partitioning — standard for logs, saves money on queries
  time_partitioning {
    type  = "DAY"
    field = "created_at"
  }

  # Clustering by pod name allows for instant lookup of specific job logs
  clustering = ["pod_name", "report_type"]

  # Table schema
  schema = <<EOF
[
  {
    "name": "pod_name",
    "type": "STRING",
    "mode": "REQUIRED",
    "description": "Name of the K8s pod that generated the report"
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED",
    "description": "Timestamp when the report was created"
  },
  {
    "name": "artifact_name",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Name of the scanned artifact"
  },
  {
    "name": "report_type",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Type of report (e.g., vulnerability or sbom)"
  },
  {
    "name": "report_data",
    "type": "JSON",
    "mode": "NULLABLE",
    "description": "The full decompressed JSON report from Trivy"
  }
]
EOF
}
