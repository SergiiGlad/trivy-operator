# Trivy Report Synchronization

This folder contains scripts to process and decompress Trivy vulnerability reports that have been exported from GKE container logs into BigQuery.

## Getting Started

### Setup

To set up your local environment and install the necessary dependencies, execute the following commands from the project root:

```bash
# Create a Python virtual environment
python3 -m venv .venv

# Activate the virtual environment
source .venv/bin/activate

# Install required libraries
pip3 install -r requirements.txt
```

Once the Terraform infrastructure is successfully deployed and the BigQuery dataset and `trivy_vulnerabilities_clean` table have been created, you can run the synchronization script.

### Usage

Listing Available Jobs
To view a list of all unique Trivy scan jobs that have generated logs in a specific source table, use the following script:
```bash
python3 scripts/list_trivy_jobs.py --source <PROJECT_ID>.<DATASET_ID>.<TABLE_NAME> 
```

**Example**
```bash
python3 scripts/list_trivy_jobs.py --source dynamic-link-1ca0e.bq_trivy_logs_flows.stdout_20260420
```
output
```bash
[*] Fetching Trivy jobs with reports from: dynamic-link-1ca0e.bq_trivy_logs_flows.stdout_20260420...
[*] Validating 9 potential jobs found in logs...
[+] Found 5 jobs with valid vulnerability reports:
  - scan-vulnerabilityreport-65679cc766-7rcc4
  - scan-vulnerabilityreport-65bd779776-f4zdv
  - scan-vulnerabilityreport-6d94486644-mmlqv
  - scan-vulnerabilityreport-77c64f5d85-glwhr
  - scan-vulnerabilityreport-b6b877ddd-2pcxf
```

Run the following command to process reports from a specific source log table (e.g., a table created by the log sink for a specific date):

```bash
python3 scripts/sync_trivy_reports.py --source <PROJECT_ID>.<DATASET_ID>.<TABLE_NAME>
```

**Example:**
```bash
python3 scripts/sync_trivy_reports.py --source dynamic-link-1ca0e.bq_trivy_logs_flows.stdout_20260420
```
Output
```bash
[*] Analyzing state of scan jobs using source: dynamic-link-1ca0e.bq_trivy_logs_flows.stdout_20260420...
[*] Found 9 new reports. Starting processing...
[*] Processing: scan-vulnerabilityreport-6d94486644-mmlqv
[+] Successfully handled: scan-vulnerabilityreport-6d94486644-mmlqv
[*] Processing: scan-vulnerabilityreport-65679cc766-7rcc4
[+] Successfully handled: scan-vulnerabilityreport-65679cc766-7rcc4
[*] Processing: scan-vulnerabilityreport-79546ccb58-46b4l
[*] Skipping scan-vulnerabilityreport-79546ccb58-46b4l: No vulnerability data found.
[+] Successfully handled: scan-vulnerabilityreport-79546ccb58-46b4l
[*] Processing: scan-vulnerabilityreport-86cf884955-mlgps
[*] Skipping scan-vulnerabilityreport-86cf884955-mlgps: No vulnerability data found.
[+] Successfully handled: scan-vulnerabilityreport-86cf884955-mlgps
[*] Processing: scan-vulnerabilityreport-65bd779776-f4zdv
[+] Successfully handled: scan-vulnerabilityreport-65bd779776-f4zdv
[*] Processing: scan-vulnerabilityreport-dc5dd49cb-xfnsh
[*] Skipping scan-vulnerabilityreport-dc5dd49cb-xfnsh: No vulnerability data found.
[+] Successfully handled: scan-vulnerabilityreport-dc5dd49cb-xfnsh
[*] Processing: scan-vulnerabilityreport-b6b877ddd-2pcxf
[+] Successfully handled: scan-vulnerabilityreport-b6b877ddd-2pcxf
[*] Processing: scan-vulnerabilityreport-dc5dd49cb-xdncj
[*] Skipping scan-vulnerabilityreport-dc5dd49cb-xdncj: No vulnerability data found.
[+] Successfully handled: scan-vulnerabilityreport-dc5dd49cb-xdncj
[*] Processing: scan-vulnerabilityreport-77c64f5d85-glwhr
[+] Successfully handled: scan-vulnerabilityreport-77c64f5d85-glwhr
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