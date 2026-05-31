# Stock Market Analytics Platform

A **production-grade data pipeline** showcasing modern data stack best practices: ingest public stock market data via **Fivetran** → warehouse in **Snowflake** → transform using **dbt medallion architecture** → visualize in **Looker Studio**.

![Architecture](docs/architecture.md)

## 🏗️ Architecture

```
Alpha Vantage API (Public Stock Data)
         ↓
    Fivetran (Ingestion)
         ↓
  Snowflake (Warehouse)
    ├── BRONZE (raw)
    ├── SILVER (cleaned)
    └── GOLD (business logic)
         ↓
   Looker Studio (Dashboards)
```

## 🎯 Project Highlights

- **Medallion Architecture** — Separated data layers (Bronze → Silver → Gold) for maintainability and data quality
- **dbt Best Practices** — Tests, documentation, data lineage, and version control
- **Snowflake Optimization** — Proper schema design, clustering, and permissions
- **Looker Studio** — Interactive dashboards for stock analysis
- **Fivetran Integration** — Automated data ingestion ready to trigger dbt jobs
- **GitHub-Ready** — Version control, CI/CD hooks (future), and team collaboration

## 📁 Project Structure

```
stock-market-analytics/
├── .gitignore
├── README.md
├── docs/
│   ├── architecture.md
│   ├── setup_guide.md
│   ├── fivetran_setup.md
│   └── looker_studio_setup.md
│
├── snowflake/
│   ├── 01_setup_warehouse.sql       # Warehouse, databases, roles
│   ├── 02_create_bronze_schema.sql  # Bronze layer (Fivetran landing)
│   ├── 03_create_silver_schema.sql  # Silver layer (staging)
│   └── 04_create_gold_schema.sql    # Gold layer (marts)
│
└── dbt/
    ├── dbt_project.yml
    ├── profiles.yml
    ├── README.md
    ├── models/
    │   ├── bronze/
    │   │   └── _sources.yml
    │   ├── silver/
    │   │   ├── stg_stock_prices.sql
    │   │   ├── stg_stock_metadata.sql
    │   │   └── _stg_models.yml
    │   └── gold/
    │       ├── fct_daily_returns.sql
    │       ├── fct_price_movements.sql
    │       ├── dim_stocks.sql
    │       ├── dim_dates.sql
    │       └── _gold_models.yml
    ├── macros/
    │   └── generate_series.sql
    ├── tests/
    │   ├── assert_positive_price.sql
    │   └── assert_returns_between_bounds.sql
    └── seeds/
        └── stock_symbols.csv
```

## 🚀 Quick Start

### Prerequisites
- **Snowflake** account with compute warehouse
- **Fivetran** account with Alpha Vantage connector
- **dbt** installed locally (`pip install dbt-snowflake`)
- **Git** for version control
- **Looker Studio** account (free)

### Step 1: Snowflake Setup
```bash
# Connect to your Snowflake account
snowsql -a <account_id> -u <username>

# Run setup scripts in order
\! cat snowflake/01_setup_warehouse.sql | snowsql -a <account_id> -u <username>
\! cat snowflake/02_create_bronze_schema.sql | snowsql -a <account_id> -u <username>
\! cat snowflake/03_create_silver_schema.sql | snowsql -a <account_id> -u <username>
\! cat snowflake/04_create_gold_schema.sql | snowsql -a <account_id> -u <username>
```

### Step 2: Configure Fivetran
See [fivetran_setup.md](docs/fivetran_setup.md) for:
- Creating Alpha Vantage connector
- Mapping to Snowflake BRONZE schema
- Setting up daily sync schedule

### Step 3: dbt Configuration
```bash
cd dbt/
# Update profiles.yml with Snowflake credentials
# Then run:
dbt deps
dbt seed  # Load stock symbols lookup table
dbt run
dbt test
dbt docs generate
```

### Step 4: Looker Studio Dashboards
See [looker_studio_setup.md](docs/looker_studio_setup.md) for:
- Connecting to Snowflake GOLD schema
- Creating visualization dashboards
- Setting up data refresh schedule

## 📊 Data Models

### Bronze Layer
- **RAW_STOCKS_DAILY** — Fivetran lands daily stock prices here (no transformations)
- **RAW_STOCKS_INFO** — Stock metadata (symbols, names, sectors)

### Silver Layer
- **STG_STOCK_PRICES** — Cleaned, deduplicated daily prices with validation
- **STG_STOCK_METADATA** — Standardized stock attributes

### Gold Layer
**Fact Tables:**
- **FCT_DAILY_RETURNS** — Daily price changes, returns, volatility
- **FCT_PRICE_MOVEMENTS** — Technical indicators (MA, RSI, Bollinger Bands prep)

**Dimension Tables:**
- **DIM_STOCKS** — Stock symbols, sectors, market cap
- **DIM_DATES** — Time dimension (year, month, quarter, day of week)

## 🔍 Data Quality

All models include dbt tests:
- ✅ Not null checks on primary keys
- ✅ Uniqueness constraints
- ✅ Referential integrity (stock symbols)
- ✅ Custom tests (prices > 0, returns between -50% and +50%)
- ✅ Schema validation

Run tests: `dbt test`

## 📚 Documentation

- `dbt docs generate` — Auto-generates data lineage and column-level docs
- `dbt docs serve` — View in browser at localhost:8000

## 🔄 Fivetran → dbt Integration (Future)

Once Fivetran detects new data in Bronze:
1. Fivetran API call triggers dbt Cloud job
2. dbt transforms Bronze → Silver → Gold
3. Looker Studio auto-refreshes dashboards

## 🛠️ Development

### Local Testing
```bash
cd dbt/
dbt run --select tag:staging
dbt test --select tag:staging
```

### Branching Strategy
- `main` — Production (deployed models)
- `develop` — Integration branch
- `feature/*` — Feature branches (new models, tests)

Create pull requests with:
- Model changes documented
- Test coverage for new logic
- dbt docs updated

## 📈 Dashboard Examples

1. **Price Tracker** — Daily prices, moving averages, support/resistance
2. **Returns Analysis** — Daily/weekly/monthly returns by stock
3. **Market Overview** — Sector performance, top gainers/losers
4. **Volatility Heatmap** — Stock volatility trends
5. **Correlation Matrix** — Inter-stock correlations

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| dbt can't connect to Snowflake | Check profiles.yml credentials and network access |
| Fivetran sync fails | Verify Alpha Vantage API key and rate limits |
| Data gaps in Silver | Check Bronze layer for missing/malformed records |
| Looker Studio won't refresh | Confirm Snowflake GOLD schema permissions |

## 📖 Additional Resources

- [dbt Documentation](https://docs.getdbt.com)
- [Snowflake SQL Reference](https://docs.snowflake.com/en/sql-reference)
- [Fivetran Docs](https://fivetran.com/docs)
- [Looker Studio Help](https://support.google.com/looker-studio)

## 📝 License

This is a portfolio project. Feel free to fork and adapt for your own use.

---

**Built with ❤️ for the modern data stack**
