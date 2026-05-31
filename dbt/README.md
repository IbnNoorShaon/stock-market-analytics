# dbt Project: Stock Market Analytics

## Overview

This dbt project transforms raw stock market data from Fivetran into analytics-ready models using the **medallion architecture** (Bronze → Silver → Gold).

## Project Structure

```
dbt/
├── models/
│   ├── bronze/          # Raw data from Fivetran (no transformations)
│   ├── silver/          # Cleaned, validated data (staging layer)
│   └── gold/            # Business logic, facts, dimensions (marts)
│       ├── facts/       # Fact tables (fct_*)
│       └── dimensions/  # Dimension tables (dim_*)
├── tests/               # Custom data quality tests
├── macros/              # Reusable dbt logic
├── seeds/               # CSV data (stock symbols lookup)
├── dbt_project.yml      # dbt configuration
├── profiles.yml.example # Template for Snowflake connection
└── README.md            # This file
```

## Setup

### 1. Install dbt
```bash
pip install dbt-snowflake
```

### 2. Configure Snowflake Connection
```bash
# Copy the example to actual profiles.yml
cp profiles.yml.example profiles.yml

# Edit profiles.yml with your Snowflake credentials
# Keep this file in ~/.dbt/ or in the dbt/ project directory
```

### 3. Install Dependencies
```bash
cd dbt/
dbt deps
```

### 4. Load Seed Data (Stock Symbols)
```bash
dbt seed
```

This loads `stock_symbols.csv` into `GOLD.STOCK_SYMBOLS` table.

## Running the Pipeline

### Development
```bash
# Run all models
dbt run

# Run specific layer
dbt run --select tag:staging
dbt run --select tag:marts

# Run with specific profile
dbt run --profiles-dir ~/.dbt
```

### Testing
```bash
# Run all tests
dbt test

# Run tests for specific model
dbt test --select stg_stock_prices

# Run only generic tests (not custom)
dbt test --schema
```

### Documentation
```bash
# Generate documentation
dbt docs generate

# Serve docs locally
dbt docs serve
# Visit http://localhost:8000 in browser
```

## Data Layers

### Bronze (RAW)
**Source**: Fivetran lands raw data here
- `RAW_STOCKS_DAILY` — Daily OHLCV data
- `RAW_STOCKS_INFO` — Company metadata

### Silver (STAGING)
**Purpose**: Clean, deduplicate, validate
- `STG_STOCK_PRICES` — Cleaned prices with calculated fields
- `STG_STOCK_METADATA` — Standardized company info

**Tests**: Not null, positive prices, valid ranges

### Gold (MARTS)
**Purpose**: Business logic, analytics-ready

**Fact Tables**:
- `FCT_DAILY_RETURNS` — Daily returns, OHLC, volume
- `FCT_PRICE_MOVEMENTS` — Moving averages, volatility, momentum

**Dimension Tables**:
- `DIM_STOCKS` — Stock metadata, market cap categories
- `DIM_DATES` — Time attributes, year/month/quarter

## Key Macros

### `generate_surrogate_key`
Creates consistent surrogate keys for facts and dimensions.
```sql
{{ dbt_utils.generate_surrogate_key(['stock_id', 'date']) }}
```

## Variables

Defined in `dbt_project.yml`:

```yaml
vars:
  start_date: '2024-01-01'  # Filter data from this date
  api_rate_limit_calls: 5
  api_rate_limit_interval_seconds: 60
```

Override in command:
```bash
dbt run --vars '{"start_date": "2023-01-01"}'
```

## Common Commands

| Command | Purpose |
|---------|---------|
| `dbt run` | Execute all models |
| `dbt test` | Run data quality tests |
| `dbt docs generate && dbt docs serve` | Generate & view documentation |
| `dbt debug` | Verify Snowflake connection |
| `dbt freshness` | Check source data freshness |
| `dbt snapshot` | Create point-in-time snapshot |

## Troubleshooting

### Can't connect to Snowflake
```bash
dbt debug
```
Check credentials in `profiles.yml` and network access.

### Model fails with "source not found"
- Ensure Fivetran has synced data to Bronze schema
- Check source names in `models/bronze/_sources.yml`

### Tests are failing
```bash
dbt test --select model_name
dbt test --select tag:gold
```

### Seed data won't load
```bash
dbt seed --full-refresh
dbt seed --show  # See what's being loaded
```

## Performance Tuning

### Reduce model execution time
```bash
# Run in parallel
dbt run --threads 8

# Run only changed models
dbt run --select state:modified+
```

### Optimize Snowflake warehouse
```bash
# Use smaller warehouse for development
profile: dev → warehouse: XSMALL_WH

# Use larger for production
profile: prod → warehouse: LARGE_WH
```

## Advanced

### Running dbt in Fivetran

Once Fivetran → Snowflake is set up:

1. Set up dbt Cloud account
2. Create dbt Cloud job for this project
3. Configure Fivetran to trigger dbt job after sync
4. dbt transforms data automatically

### Git Integration

Standard dbt git workflow:
```bash
git checkout -b feature/new-model
# Make changes to models/
git add .
git commit -m "Add new stock volatility model"
git push
# Create PR for review
```

## Resources

- [dbt Docs](https://docs.getdbt.com)
- [Snowflake + dbt Guide](https://docs.getdbt.com/guides/snowflake)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [dbt Utils](https://github.com/dbt-labs/dbt-utils)
