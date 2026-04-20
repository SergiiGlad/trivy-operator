# Terraform Infrastructure for Trivy Operator

This directory contains the Terraform configuration used to provision the Google Cloud infrastructure required for running the Trivy Operator on GKE and automating the export of vulnerability reports to BigQuery.

## Managed Resources

### 1. Google Kubernetes Engine (GKE)
Defined in `gke.tf`, this module sets up:
*   **Primary Cluster**: A GKE cluster named `trivy-gke-cluster` with the default node pool removed for better management.
*   **Node Pool**: A managed node pool using `e2-medium` instances, configured with the necessary OAuth scopes to interact with Google Cloud APIs.

### 2. BigQuery (Data Warehouse)
Defined in `bq.tf`, this module manages the data storage layer:
*   **Dataset**: `bq_trivy_logs_flows`, which acts as the container for all security-related log data.
*   **Processed Table**: `trivy_vulnerabilities_clean`. This table is optimized for analysis with:
    *   **Time Partitioning**: Partitioned by the `created_at` timestamp to reduce query costs.
    *   **Clustering**: Clustered by `pod_name` and `report_type` for high-performance lookups of specific scan results.
    *   **JSON Schema**: Uses the native `JSON` type for the `report_data` column to allow for flexible querying of nested Trivy reports.

### 3. Logging & Log Sink (Automation)
Defined in `log_sink.tf`, this provides the bridge between GKE and BigQuery:
*   **Log Sink**: A project-level logging sink that captures logs from the `trivy-system` namespace where scan jobs run. It uses a regex filter to identify `scan-vulnerabilityreport-*` pods.
*   **Permissions**: Automatically assigns the `roles/bigquery.dataEditor` IAM role to the Sink's unique service account, allowing it to write raw logs directly into BigQuery.

### 4. Helm Integration
Configured in `providers.tf`, the Helm provider is dynamically linked to the GKE cluster's endpoint and credentials. This allows Terraform to manage the lifecycle of the **Trivy Operator** deployment within the cluster using standard Helm charts.

## Deployment Workflow

1.  **Initialize**: `terraform init` to download providers (Google and Helm).
2.  **Configuration**: Ensure `variables.tf` (or a `.tfvars` file) contains your `project_id`, `region`, and `zone`.
3.  **Apply**: `terraform apply` to create the infrastructure.

## Outputs
After a successful apply, Terraform will provide:
*   `gke_cluster_name`: The name of your new cluster.
*   `bigquery_table_full_path`: The full reference needed for Python synchronization scripts.
*   `bigquery_dataset_id`: The ID of the log destination.