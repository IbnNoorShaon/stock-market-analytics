# Fivetran Setup Guide

## Overview

Fivetran will automatically ingest daily stock data from Alpha Vantage API into Snowflake's BRONZE schema.

## Prerequisites

1. ✅ Snowflake account with COMPUTE_WH and STOCK_ANALYTICS database (created in previous step)
2. ✅ Fivetran account (free tier sufficient)
3. ✅ Alpha Vantage API key (free registration at https://www.alphavantage.co/api)

## Step 1: Get Alpha Vantage API Key

1. Visit https://www.alphavantage.co/api
2. Sign up for free account
3. Copy your API key (you'll receive it via email)
4. Note: Free tier has rate limits (5 calls/min, 500 calls/day)

## Step 2: Create Snowflake Connection in Fivetran

### In Fivetran Dashboard:

1. Navigate to **Connectors** → **Create New Connector**
2. Search for **Snowflake** (destination)
3. Click **Configure**

### Snowflake Configuration:

| Field | Value |
|-------|-------|
| Host | Your Snowflake account ID (e.g., `xy12345.us-east-1`) |
| Port | 443 |
| Database | STOCK_ANALYTICS |
| Schema | BRONZE |
| Username | Your Snowflake user |
| Password | Your Snowflake password |
| Warehouse | COMPUTE_WH |
| Role | ANALYTICS_ROLE |

4. Click **Test Connection** (should succeed)
5. Click **Save Configuration**
6. Set sync frequency to **Daily** (or your preference)

## Step 3: Create Alpha Vantage Source Connector

### Via Fivetran API Connector (Recommended):

Fivetran doesn't have a native Alpha Vantage connector, so use the **API Connector**:

1. In Fivetran, click **+ Connector** → **API Request**
2. Configure the source:

### REST API Configuration:

**Endpoint URL**:
```
https://www.alphavantage.co/query
```

**Query Parameters**:
```
function=TIME_SERIES_DAILY
symbol=AAPL
apikey=YOUR_API_KEY_HERE
outputsize=full
datatype=json
```

**Request Headers**:
```
Authorization: (leave empty for Alpha Vantage)
```

**Response Mapping**:
Map the response to Snowflake tables:

**Table 1: RAW_STOCKS_DAILY**
```json
{
  "SYMBOL": "from query param",
  "DATE": "from time_series key",
  "OPEN_PRICE": "from 1. open",
  "HIGH_PRICE": "from 2. high",
  "LOW_PRICE": "from 3. low",
  "CLOSE_PRICE": "from 4. close",
  "VOLUME": "from 5. volume"
}
```

### Alternative: Python Script (Advanced)

If Fivetran API connector is complex, create a Python script locally:

```python
# fetch_stock_data.py
import requests
import pandas as pd
from snowflake.connector import connect

API_KEY = "YOUR_API_KEY"
SYMBOLS = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", ...]

sf_conn = connect(
    user="YOUR_USER",
    password="YOUR_PASSWORD",
    account="YOUR_ACCOUNT",
    warehouse="COMPUTE_WH",
    database="STOCK_ANALYTICS",
    schema="BRONZE"
)

for symbol in SYMBOLS:
    url = f"https://www.alphavantage.co/query"
    params = {
        "function": "TIME_SERIES_DAILY",
        "symbol": symbol,
        "apikey": API_KEY,
        "outputsize": "full",
        "datatype": "json"
    }
    
    response = requests.get(url, params=params).json()
    
    # Parse and insert into Snowflake
    # (implementation details)
    
sf_conn.close()
```

Then schedule with:
- **Airflow** (complex workflows)
- **Cron job** (simple daily execution)
- **GitHub Actions** (CI/CD automation)

## Step 4: Create Multiple Connector Instances

Create a separate connector for each stock symbol (or run script for batch):

### Fivetran Config for Each Stock:

**For AAPL**:
```
Connector Name: Alpha Vantage - AAPL
Source Type: API Request
Symbol Parameter: AAPL
Destination: SNOWFLAKE (STOCK_ANALYTICS.BRONZE)
Sync Frequency: Daily @ 4:30 PM EST
```

**For MSFT**:
```
Connector Name: Alpha Vantage - MSFT
Source Type: API Request
Symbol Parameter: MSFT
Destination: SNOWFLAKE (STOCK_ANALYTICS.BRONZE)
Sync Frequency: Daily @ 4:30 PM EST
```

Repeat for: GOOGL, AMZN, NVDA, TSLA, META, JPM, BAC, GS, IBM, INTC, AMD, XOM, CVX, JNJ, PFE, KO, PEP, WMT

## Step 5: Configure Sync Schedule

In Fivetran:

1. Click each connector → **Scheduling**
2. Set **Sync Frequency**: Daily
3. Set **Sync Time**: 4:30 PM EST (after US market close)
4. Enable **Run on Schedule**

## Step 6: Monitor First Sync

1. Click **Start Initial Sync**
2. Monitor sync progress in Fivetran dashboard
3. Check Snowflake tables:

```sql
use database STOCK_ANALYTICS;
use schema BRONZE;

select count(*) from RAW_STOCKS_DAILY;
select count(*) from RAW_STOCKS_INFO;
select distinct SYMBOL from RAW_STOCKS_DAILY;
```

## Step 7: Test Data Quality

```sql
-- Check for gaps or data issues
select
    symbol,
    count(*) as row_count,
    min(date) as earliest_date,
    max(date) as latest_date
from RAW_STOCKS_DAILY
group by symbol
order by symbol;

-- Check for null prices
select * from RAW_STOCKS_DAILY
where CLOSE_PRICE is null or VOLUME is null;
```

## Step 8: (Optional) Set Up dbt Trigger

Once Fivetran sync is stable, configure dbt Cloud to run after Fivetran completes:

1. In Fivetran, navigate to **Connector Settings** → **Webhooks**
2. Add webhook:
   ```
   URL: https://cloud.dbtlabs.com/api/v2/webhooks/
   Trigger: On successful sync
   Method: POST
   ```
3. Configure dbt Cloud to accept the webhook

See [dbt Cloud Fivetran Integration](https://docs.fivetran.com/hc/en-us/articles/9146316467871-DBT-Cloud-Integration) for detailed steps.

## Troubleshooting

### Issue: "Invalid API Key"
- Verify Alpha Vantage API key is correct
- Check API key hasn't expired (reactivate in Alpha Vantage dashboard)

### Issue: "Rate limit exceeded"
- Alpha Vantage free tier: 5 calls/min, 500 calls/day
- Solution: Extend sync intervals, upgrade API tier, or use batch processing

### Issue: "Snowflake authentication failed"
- Verify Snowflake user has ANALYTICS_ROLE
- Check password hasn't changed
- Confirm warehouse COMPUTE_WH exists and is active

### Issue: "No data in RAW_STOCKS_DAILY"
- Check sync logs in Fivetran dashboard
- Verify API response is returning data
- Manually test Alpha Vantage endpoint:
  ```
  https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=AAPL&apikey=YOUR_KEY
  ```

### Issue: "Duplicate rows" in BRONZE tables
- Expected behavior initially (full refresh)
- After first sync, Fivetran will upsert on unique constraint

## Cost Considerations

| Service | Cost | Notes |
|---------|------|-------|
| Alpha Vantage | Free | 500 calls/day limit |
| Fivetran | Free tier | 1M rows/month included |
| Snowflake | ~$10-20/month | 1 credit/hour for XSMALL WH |
| **Total** | **~$10-20/month** | All within free/trial tiers |

## Next Steps

After Fivetran successfully syncs data:

1. ✅ Run Snowflake setup scripts (if not done)
2. ✅ Configure dbt (see dbt/README.md)
3. ✅ Run dbt transformations: `dbt run && dbt test`
4. ✅ Connect Looker Studio to GOLD schema
5. 📊 Build dashboards

## Useful Commands

```sql
-- Monitor Fivetran syncs
select * from STOCK_ANALYTICS.BRONZE.RAW_STOCKS_DAILY
where _FIVETRAN_SYNCED > current_timestamp - interval '24 hours'
order by _FIVETRAN_SYNCED desc;

-- Check data completeness
select symbol, max(date) as latest_date
from STOCK_ANALYTICS.BRONZE.RAW_STOCKS_DAILY
group by symbol
order by symbol;
```

## References

- [Alpha Vantage API Docs](https://www.alphavantage.co/documentation/)
- [Fivetran Documentation](https://fivetran.com/docs)
- [Snowflake Fivetran Connector](https://fivetran.com/docs/destinations/snowflake)
