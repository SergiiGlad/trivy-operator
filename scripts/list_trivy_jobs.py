import argparse
import base64
import bz2
import json
from google.cloud import bigquery

def is_report_useful(data):
    """Validates if the report contains actual vulnerability data."""
    # Matches the logic in sync_trivy_reports.py
    return "vulnerabilities" in json.dumps(data).lower()

def get_source_pods(client, source_table):
    """Retrieves the set of all unique pod_names from source that have logs."""
    query = f"""
        SELECT DISTINCT resource.labels.pod_name as pod_name 
        FROM `{source_table}` 
        WHERE resource.labels.pod_name LIKE 'scan-vulnerabilityreport-%'
    """
    query_job = client.query(query)
    return [row.pod_name for row in query_job]

def validate_pod_report(client, pod_name, source_table):
    """Fetches and decompresses the payload to check for vulnerability data."""
    query = f"""
    SELECT STRING_AGG(textPayload, '' ORDER BY timestamp) as full_payload
    FROM `{source_table}`
    WHERE resource.labels.pod_name = '{pod_name}'
    """
    try:
        results = list(client.query(query).result())
        if not results or not results[0].full_payload:
            return False
        binary_data = base64.b64decode(results[0].full_payload)
        decompressed_data = bz2.decompress(binary_data)
        data = json.loads(decompressed_data.decode('utf-8'))
        return is_report_useful(data)
    except Exception:
        return False

def main():
    parser = argparse.ArgumentParser(description="List all Trivy scan jobs that have reports in the source BigQuery table.")
    parser.add_argument("--source", required=True, help="Full BQ source table path (project.dataset.table)")
    args = parser.parse_args()

    client = bigquery.Client()
    
    print(f"[*] Fetching Trivy jobs with reports from: {args.source}...")
    
    try:
        pods = get_source_pods(client, args.source)
        print(f"[*] Validating {len(pods)} potential jobs found in logs...")

        # Filter for pods that actually contain vulnerability reports
        valid_pods = sorted([p for p in pods if validate_pod_report(client, p, args.source)])

        if not valid_pods:
            print("[-] No Trivy scan reports found in the specified source table.")
            return

        print(f"[+] Found {len(valid_pods)} jobs with valid vulnerability reports:")
        for pod in valid_pods:
            print(f"  - {pod}")
            
    except Exception as e:
        print(f"[!] Error querying BigQuery: {e}")
        print("[?] Ensure your project ID and dataset/table names are correct and you have the necessary permissions.")

if __name__ == "__main__":
    main()
