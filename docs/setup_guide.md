# Complete Setup Guide

## Project Overview

This is a **production-grade stock market analytics platform** demonstrating modern data engineering best practices.

**Tech Stack**:
- 📊 Data Source: Alpha Vantage API (public stock data)
- 📥 Ingestion: Fivetran (automated daily sync)
- 🏢 Warehouse: Snowflake (data storage & compute)
- 🔄 Transformation: dbt (medallion architecture)
- 📈 Visualization: Looker Studio (dashboards)
- 🔗 Version Control: GitHub

**Timeline**: ~2-4 hours to complete initial setup

---

## Phase 1: Snowflake Setup (30 minutes)

### 1.1 Create Snowflake Account
- Visit https://www.snowflake.com/
- Sign up for free trial (30 days)
- Region: Choose closest to you (e.g., us-east-1)
- Edition: Standard

### 1.2 Run Setup Scripts
1. Log in to Snowflake Web UI
2. Create a new SQL worksheet
3. Copy & run scripts in order:
   ```
   01_setup_warehouse.sql
   02_create_bronze_schema.sql
   03_create_silver_schema.sql
   04_create_gold_schema.sql
   ```
4. Verify all tables/schemas created:
   ```sql
   show databases;
   show schemas in database STOCK_ANALYTICS;
   ```

---

## Phase 2: Fivetran Setup (45 minutes)

### 2.1 Get Alpha Vantage API Key
1. Visit https://www.alphavantage.co/
2. Click "GET FREE API KEY"
3. Fill email & agree to terms
4. Copy API key from confirmation email

### 2.2 Create Fivetran Account
1. Visit https://fivetran.com/
2. Sign up for free account
3. Create Snowflake destination (see docs/fivetran_setup.md for details)

### 2.3 Create Data Connectors
1. Set up Alpha Vantage → Snowflake connector
2. Map to `STOCK_ANALYTICS.BRONZE.RAW_STOCKS_DAILY`
3. Schedule for daily sync @ 4:30 PM EST
4. Run initial sync to test

### 2.4 Verify Data
```sql
use database STOCK_ANALYTICS;
use schema BRONZE;

select count(*) as row_count from RAW_STOCKS_DAILY;
select distinct SYMBOL from RAW_STOCKS_DAILY;
```

---

## Phase 3: dbt Setup (45 minutes)

### 3.1 Install dbt
```bash
pip install dbt-snowflake
dbt --version  # Verify installation
```

### 3.2 Configure dbt Project
```bash
cd dbt/

# Copy example profiles
cp profiles.yml.example profiles.yml

# Edit with your Snowflake credentials
nano profiles.yml  # Or use your editor
```

Update these fields:
```yaml
stock_market_analytics:
  outputs:
    dev:
      account: [YOUR_ACCOUNT_ID]
      user: [YOUR_USERNAME]
      password: [YOUR_PASSWORD]
```

### 3.3 Test dbt Connection
```bash
dbt debug
# Should output: "All checks passed!"
```

### 3.4 Load Seed Data
```bash
dbt seed
```

Verify in Snowflake:
```sql
select count(*) from STOCK_ANALYTICS.GOLD.STOCK_SYMBOLS;
```

### 3.5 Run dbt Pipeline
```bash
# Install packages
dbt deps

# Run transformations
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
# Visit http://localhost:8000
```

### 3.6 Verify Models
```sql
use database STOCK_ANALYTICS;

-- Check Silver layer
select count(*) from SILVER.STG_STOCK_PRICES;

-- Check Gold layer
select count(*) from GOLD.FCT_DAILY_RETURNS;
select count(*) from GOLD.DIM_STOCKS;
```

---

## Phase 4: Looker Studio Setup (30 minutes)

### 4.1 Create Looker Studio Report
1. Visit https://looker.studio/
2. Sign in with Google account
3. Click **Create** → **Report**

### 4.2 Connect Snowflake
1. Click **Resource** → **Manage data sources**
2. Click **Create new data source**
3. Select **Snowflake**
4. Enter credentials:
   - Account: `xy12345.us-east-1`
   - Database: `STOCK_ANALYTICS`
   - Schema: `GOLD`
   - Username/Password: Your Snowflake user
5. Click **Authenticate**

### 4.3 Select Tables
1. Database: `STOCK_ANALYTICS`
2. Schema: `GOLD`
3. Select `FCT_DAILY_RETURNS` as first data source

Name it: `Stock Daily Returns`

### 4.4 Build Sample Dashboard
1. Add **Time Series Chart**
   - Date (X-axis) → `DATE`
   - Metric → `CLOSE_PRICE` (average)
   - Symbol filter (dropdown)

2. Add **Column Chart**
   - Symbol (X-axis)
   - Metric → `DAILY_RETURN_PCT` (average)

3. Add **Filters**
   - Symbol: Multi-select dropdown
   - Date range: Last 1 year

### 4.5 Publish Dashboard
1. Click **Share**
2. Set to "Viewer can access"
3. Copy shareable link

---

## Phase 5: Verification Checklist

### Data Ingestion
- [ ] Fivetran connector running daily
- [ ] Data appearing in `BRONZE.RAW_STOCKS_DAILY`
- [ ] Data appearing in `BRONZE.RAW_STOCKS_INFO`

### dbt Transformation
- [ ] `dbt run` completes without errors
- [ ] `dbt test` passes all tests
- [ ] 4 Gold models created:
  - [ ] `FCT_DAILY_RETURNS` (rows: ~5,000-10,000)
  - [ ] `FCT_PRICE_MOVEMENTS` (rows: ~5,000-10,000)
  - [ ] `DIM_STOCKS` (rows: ~20)
  - [ ] `DIM_DATES` (rows: 730)

### Looker Studio
- [ ] Snowflake connection successful
- [ ] Price chart displays data
- [ ] Returns chart displays data
- [ ] Filters work correctly
- [ ] Dashboard refreshes daily

### Documentation
- [ ] dbt docs generate successful
- [ ] README.md reviewed
- [ ] Architecture diagram understood

---

## Usage

### Daily Workflow

1. **Data Ingestion** (Automatic @ 4:30 PM EST)
   - Fivetran syncs new stock data

2. **Transformation** (Manual or Scheduled)
   ```bash
   dbt run && dbt test
   ```

3. **Visualization** (Automatic)
   - Looker Studio auto-refreshes at 5:00 PM EST

### Useful Commands

```bash
# Run specific model
dbt run --select fct_daily_returns

# Run tests for specific model
dbt test --select stg_stock_prices

# View data lineage
dbt docs serve

# Full refresh (regenerate all data)
dbt run --full-refresh

# Run in production schema
dbt run --target prod
```

### Monitoring

**Fivetran**:
- Dashboard → Monitor sync status
- Check for failed connectors
- Verify daily sync completed

**dbt**:
- `dbt test` output → Review any failed tests
- dbt docs → Check model lineage

**Looker Studio**:
- Last refresh time indicator
- Monitor query performance
- Check for missing/stale data

---

## Troubleshooting

### Fivetran Issues
**Problem**: Sync fails
**Solution**:
```
1. Check Alpha Vantage API key is valid
2. Verify rate limits not exceeded
3. Check Snowflake warehouse is running
4. Review Fivetran logs for error details
```

### dbt Issues
**Problem**: `dbt run` fails
**Solution**:
```bash
# Check connection
dbt debug

# Check for SQL syntax errors
dbt parse

# Review error logs
dbt run --debug
```

### Looker Studio Issues
**Problem**: "Permission denied"
**Solution**:
```sql
-- Grant select on GOLD schema
grant select on all tables in schema STOCK_ANALYTICS.GOLD 
  to role ANALYTICS_ROLE;
```

---

## Cost Breakdown (Monthly)

| Service | Cost | Notes |
|---------|------|-------|
| Alpha Vantage | $0 | Free tier sufficient |
| Fivetran | $0 | Free tier (1M rows/month) |
| Snowflake | $15-30 | ~1-2 credits/day |
| Looker Studio | $0 | Free |
| **Total** | **$15-30** | Within free tier limits |

---

## Next Steps

### Immediate (Week 1)
- [ ] Complete all 5 phases
- [ ] Verify all components working
- [ ] Review documentation
- [ ] Share Looker Studio dashboard

### Short Term (Week 2-4)
- [ ] Add more stocks/sectors
- [ ] Create additional Looker dashboards
- [ ] Document business logic
- [ ] Prepare portfolio presentation

### Medium Term (Month 2+)
- [ ] Push to GitHub
- [ ] Set up CI/CD pipeline
- [ ] Add advanced metrics (Sharpe ratio, etc.)
- [ ] Implement real-time intra-day data
- [ ] Multi-source integration

### Long Term (Future)
- [ ] ML models for price prediction
- [ ] Advanced portfolio analytics
- [ ] Mobile app integration
- [ ] Enterprise deployment

---

## References

- [Snowflake Documentation](https://docs.snowflake.com/)
- [Fivetran Setup Guide](docs/fivetran_setup.md)
- [dbt Documentation](https://docs.getdbt.com/)
- [Looker Studio Help](https://support.google.com/looker-studio)
- [Architecture Diagram](docs/architecture.md)

---

## Support

For questions or issues:
1. Check troubleshooting section above
2. Review relevant setup guide (Snowflake/Fivetran/dbt/Looker)
3. Review error logs and documentation
4. Check GitHub issues (if published)

---

**Happy analyzing! 📊**
