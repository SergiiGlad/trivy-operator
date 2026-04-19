# GKE Trivy Operator to BigQuery Pipeline

This project implements an automated security pipeline that scans Kubernetes workloads for vulnerabilities using the **Trivy Operator** and exports the results into **Google BigQuery** for long-term analysis and reporting.

## Architecture Overview

1.  **Infrastructure (Terraform)**: Provisions a GKE cluster and a BigQuery dataset/table.
2.  **Scanning (Trivy Operator)**: Deployed via Helm, it automatically scans pods in the cluster and outputs vulnerability reports to container logs.
3.  **Ingestion (Log Sink)**: A GCP Log Sink captures these specific logs and streams them into a raw BigQuery table.
4.  **Processing (Python)**: A synchronization script processes the raw logs, handles decompression/parsing, and populates a clean, partitioned table optimized for SQL analysis.

## Repository Structure

*   [`terraform/`](./terraform/): Infrastructure as Code to set up GKE, BigQuery, and the Log Sink.
*   [`scripts/`](./scripts/): Python utilities to sync and clean the vulnerability data.

## Quick Start

### 1. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID"
```

### 2. Process Reports
After the Trivy Operator has run scans in the cluster, use the Python script to move data from the raw log sink to the clean analytical table:
```bash
python scripts/sync_trivy_reports.py --source YOUR_PROJECT.bq_trivy_logs_flows.stdout_YYYYMMDD
```

### 3. Analyze Data
You can then run SQL queries in BigQuery to find critical issues:
```sql
SELECT pod_name, report_data 
FROM `bq_trivy_logs_flows.trivy_vulnerabilities_clean`
WHERE JSON_VALUE(report_data, '$.summary.criticalCount') != '0';
```

## Prerequisites
*   Google Cloud Project with billing enabled.
*   Terraform and Python 3.9+ installed locally.