import base64
import bz2
import json
import argparse
from google.cloud import bigquery

# --- CONFIGURATION ---
TARGET_TABLE = "dynamic-link-1ca0e.bq_trivy_logs_flows.trivy_vulnerabilities_clean"

def is_report_useful(data):
    """
    Validates if the report contains actual vulnerability data.
    Trivy vulnerability reports contain a 'vulnerabilities' key.
    SBOM/CycloneDX reports usually do not.
    """
    # Convert to string and check if 'vulnerabilities' exists anywhere
    # This is a robust way to catch the key regardless of nested structure
    return "vulnerabilities" in json.dumps(data).lower()

def get_processed_pods(client):
    """Retrieves the set of pod_names already processed."""
    query = f"SELECT DISTINCT pod_name FROM `{TARGET_TABLE}`"
    query_job = client.query(query)
    return {row.pod_name for row in query_job}

def get_all_source_pods(client, source_table):
    """Retrieves the set of all unique pod_names from source."""
    query = f"""
        SELECT DISTINCT resource.labels.pod_name as pod_name 
        FROM `{source_table}` 
        WHERE resource.labels.pod_name LIKE 'scan-vulnerabilityreport-%'
    """
    query_job = client.query(query)
    return {row.pod_name for row in query_job}

def process_pod(client, pod_name, source_table):
    """Extracts, validates, and uploads data for a single pod."""
    query = f"""
    SELECT STRING_AGG(textPayload, '' ORDER BY timestamp) as full_payload
    FROM `{source_table}`
    WHERE resource.labels.pod_name = '{pod_name}'
    """
    try:
        results = list(client.query(query).result())
        if not results or not results[0].full_payload:
            return False

        # Decode and decompress
        binary_data = base64.b64decode(results[0].full_payload)
        decompressed_data = bz2.decompress(binary_data)
        data = json.loads(decompressed_data.decode('utf-8'))

        # FILTERING LOGIC: Skip if no vulnerabilities found
        if not is_report_useful(data):
            print(f"[*] Skipping {pod_name}: No vulnerability data found.")
            return True # Return True to indicate successful "handling" (so it's not retried)

        # Prepare row for insertion
        row = {
            "pod_name": pod_name,
            "created_at": data.get("CreatedAt"),
            "artifact_name": data.get("ArtifactName"),
            "report_type": "vulnerability",
            "report_data": json.dumps(data)
        }
        
        # Insert into BigQuery
        errors = client.insert_rows_json(TARGET_TABLE, [row])
        if errors:
            print(f"[!] BQ Insert Error for {pod_name}: {errors}")
            return False
        return True

    except Exception as e:
        print(f"Error processing pod {pod_name}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Sync Trivy reports from log table to clean table.")
    parser.add_argument("--source", required=True, help="Full BQ source table path (project.dataset.table)")
    args = parser.parse_args()

    client = bigquery.Client()
    
    print(f"[*] Analyzing state of scan jobs using source: {args.source}...")
    processed = get_processed_pods(client)
    all_pods = get_all_source_pods(client, args.source)
    
    # Identify pods that exist in source but not in destination
    to_process = all_pods - processed
    
    if not to_process:
        print("[+] All reports are already up to date.")
        return

    print(f"[*] Found {len(to_process)} new reports. Starting processing...")
    
    for pod in to_process:
        print(f"[*] Processing: {pod}")
        if process_pod(client, pod, args.source):
            print(f"[+] Successfully handled: {pod}")
        else:
            print(f"[!] Failed to process: {pod}")

if __name__ == "__main__":
    main()