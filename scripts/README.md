# Trivy Report Synchronization

This folder contains scripts to process and decompress Trivy vulnerability reports that have been exported from GKE container logs into BigQuery.

## Getting Started

Once the Terraform infrastructure is successfully deployed and the BigQuery dataset and `trivy_vulnerabilities_clean` table have been created, you can run the synchronization script.

### Usage

Run the following command to process reports from a specific source log table (e.g., a table created by the log sink for a specific date):

```bash
python3 scripts/sync_trivy_reports.py --source <PROJECT_ID>.<DATASET_ID>.<TABLE_NAME>
```

**Example:**
```bash
python3 scripts/sync_trivy_reports.py --source dynamic-link-1ca0e.bq_trivy_logs_flows.stdout_20260420
```

Run SQL query to see CRITICAL vulnarabilities
```SQL
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
Run SQL query to see Big Picture - high-level summary of all detected vulnerabilities grouped by severity
```SQL
SELECT 
  JSON_VALUE(vuln, '$.Severity') as severity,
  COUNT(*) as total_count
FROM `dynamic-link-1ca0e.bq_trivy_logs_flows.trivy_vulnerabilities_clean`,
UNNEST(JSON_QUERY_ARRAY(report_data, '$.Results')) as result,
UNNEST(JSON_QUERY_ARRAY(result, '$.Vulnerabilities')) as vuln
GROUP BY 1
ORDER BY 2 DESC;
```