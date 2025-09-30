# utils/bq_cost.py
import os
import json
from google.cloud import bigquery
from google.oauth2 import service_account

def how_much(sql: str, price_per_tb: float = 6.25):
    """
    Estimate how much a BigQuery SQL query will cost using a dry run.

    Args:
        sql (str): The SQL query to estimate.
        price_per_tb (float): Cost per TB scanned in USD (default $6.25).

    Prints:
        Human-readable cost estimate including KB, GB, TB, and USD.
    """
    # Load credentials from environment
    creds_json = os.environ.get("BQ_CREDENTIALS")
    if not creds_json:
        raise RuntimeError("Environment variable BQ_CREDENTIALS is not set")

    # Parse service account JSON (raw or base64)
    try:
        creds_info = json.loads(creds_json)
    except json.JSONDecodeError:
        import base64
        creds_info = json.loads(base64.b64decode(creds_json))

    creds = service_account.Credentials.from_service_account_info(creds_info)

    # Create BigQuery client
    client = bigquery.Client(credentials=creds, project=creds.project_id)

    # Run dry run
    job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    job = client.query(sql, job_config=job_config)

    bytes_scanned = job.total_bytes_processed
    gb = bytes_scanned / (1024**3)
    tb = bytes_scanned / (1024**4)
    estimated_cost = tb * price_per_tb

    print("Estimated size to scan:")
    print(f"{bytes_scanned/1024:,.0f} KB")
    print(f"{gb:,.0f} GB")
    print(f"{tb:.4f} TB")
    print("")
    print(f"Estimated cost: ${estimated_cost:.4f} (at ${price_per_tb}/TB)")
    return
