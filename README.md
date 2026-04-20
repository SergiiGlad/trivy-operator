# GKE Trivy Operator to BigQuery Pipeline

This project implements an automated security pipeline that scans Kubernetes workloads for vulnerabilities using the **Trivy Operator** and exports the results into **Google BigQuery** for long-term analysis and reporting.

## Architecture Overview

1.  **Infrastructure (Terraform)**: Provisions a GKE cluster and a BigQuery dataset/table.
2.  **Scanning (Trivy Operator)**: Deployed via Helm, it automatically scans pods in the cluster and outputs vulnerability reports to container logs.
3.  **Ingestion (Log Sink)**: A GCP Log Sink captures these specific logs and streams them into a raw BigQuery table.
4.  **Processing (Python)**: A synchronization script processes the raw logs, handles decompression/parsing, and populates a clean, partitioned table optimized for SQL analysis.

## CI/CD Pipeline

The project uses **Google Cloud Build** for automated deployments and infrastructure management, following a standard Git Flow model with `main` and `develop` branches.

There are three primary automation triggers configured in Terraform:
*   **Push to `develop`**: Automatically triggers builds and tests for the development environment.
*   **Pull Request to `main`**: Validates changes before they are merged into the production branch.
*   **Push to `main`**: Triggers the final production deployment workflow.

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
SELECT 
  pod_name,
  -- Access the specific fields inside the vulnerability object
  JSON_VALUE(vuln, '$.VulnerabilityID') as cve_id,
  JSON_VALUE(vuln, '$.Severity') as severity,
  JSON_VALUE(vuln, '$.PkgName') as package_name
FROM `dynamic-link-1ca0e.bq_trivy_logs_flows.trivy_vulnerabilities_clean`,
-- First, unnest the Results array
UNNEST(JSON_QUERY_ARRAY(report_data, '$.Results')) as result,
-- Second, unnest the Vulnerabilities array inside each Result
UNNEST(JSON_QUERY_ARRAY(result, '$.Vulnerabilities')) as vuln
WHERE JSON_VALUE(vuln, '$.Severity') = 'CRITICAL';
```

## Prerequisites
*   Google Cloud Project with billing enabled.
*   Terraform and Python 3.9+ installed locally.