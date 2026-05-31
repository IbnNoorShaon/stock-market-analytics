# System Architecture

## Data Flow Diagram

```
┌─────────────────────┐
│  Alpha Vantage API  │
│  (Public Stock Data)│
└──────────┬──────────┘
           │
           │ Daily sync
           ▼
┌─────────────────────┐
│      Fivetran       │
│  (Data Ingestion)   │
└──────────┬──────────┘
           │
           │ UPSERT
           ▼
┌──────────────────────────────────────┐
│        Snowflake Warehouse           │
│  ┌────────────────────────────────┐  │
│  │  BRONZE (Raw Data)             │  │
│  │  - RAW_STOCKS_DAILY            │  │
│  │  - RAW_STOCKS_INFO             │  │
│  └────────┬─────────────────────┬─┘  │
│           │                     │     │
│           │ dbt transform       │     │
│           ▼                     ▼     │
│  ┌────────────────────────────────┐  │
│  │  SILVER (Staging)              │  │
│  │  - STG_STOCK_PRICES            │  │
│  │  - STG_STOCK_METADATA          │  │
│  └────────┬─────────────────────┬─┘  │
│           │                     │     │
│           │ dbt aggregate       │     │
│           ▼                     ▼     │
│  ┌────────────────────────────────┐  │
│  │  GOLD (Marts)                  │  │
│  │  - FCT_DAILY_RETURNS           │  │
│  │  - FCT_PRICE_MOVEMENTS         │  │
│  │  - DIM_STOCKS                  │  │
│  │  - DIM_DATES                   │  │
│  └────────────────────────────────┘  │
└──────────┬──────────────────────────┘
           │
           │ SQL queries
           ▼
┌──────────────────────────────────────┐
│      Looker Studio Dashboards        │
│  - Price Tracker                     │
│  - Returns Analysis                  │
│  - Market Overview                   │
│  - Volatility Heatmap                │
└──────────────────────────────────────┘
```

## Component Details

### 1. Data Source: Alpha Vantage API
- **Type**: Public REST API
- **Data**: Daily stock OHLCV (Open, High, Low, Close, Volume)
- **Coverage**: 20+ major stocks (AAPL, MSFT, GOOGL, etc.)
- **Frequency**: Daily updates (market close)
- **Cost**: Free tier (limited to 5 calls/min, 500 calls/day)

### 2. Fivetran (Ingestion)
- **Role**: Automated data movement
- **Source Connector**: Alpha Vantage API
- **Destination**: Snowflake BRONZE schema
- **Load Strategy**: Full refresh (daily) → Upsert for daily prices
- **Sync Schedule**: Daily @ 4:30 PM EST (after market close)

**Key Configuration**:
- API Key: Provided by user
- Destination: `STOCK_ANALYTICS.BRONZE`
- Tables: `RAW_STOCKS_DAILY`, `RAW_STOCKS_INFO`

### 3. Snowflake (Data Warehouse)

#### BRONZE Layer (Raw)
- **Tables**: Created by Fivetran connector
- **Data Quality**: No transformations (as-is from API)
- **Retention**: 2+ years of historical data
- **Access**: Append-only for Fivetran, read for dbt

**Tables**:
```
RAW_STOCKS_DAILY
├── SYMBOL (PK)
├── DATE (PK)
├── OPEN_PRICE
├── HIGH_PRICE
├── LOW_PRICE
├── CLOSE_PRICE
├── VOLUME
└── _FIVETRAN_SYNCED

RAW_STOCKS_INFO
├── SYMBOL (PK)
├── NAME
├── SECTOR
├── MARKET_CAP
└── _FIVETRAN_SYNCED
```

#### SILVER Layer (Staging)
- **Views/Tables**: Created by dbt
- **Purpose**: Data cleaning, validation, standardization
- **Data Quality**: Tests for not-null, positive values, valid ranges
- **Lineage**: Clear traceability to Bronze sources

**Models**:
```
STG_STOCK_PRICES
├── symbol, date, open_price, close_price
├── daily_return_pct (calculated)
├── price_direction (UP/DOWN/FLAT)
└── Validations: positive prices, reasonable returns

STG_STOCK_METADATA
├── symbol, company_name, sector, market_cap
└── Validations: unique symbols, non-null keys
```

#### GOLD Layer (Analytics)
- **Tables**: Created by dbt
- **Purpose**: Business logic, aggregations, dimensional modeling
- **Design**: Fact/Dimension star schema

**Fact Tables**:
```
FCT_DAILY_RETURNS (daily grain)
├── return_id (SK)
├── stock_id (FK)
├── date (FK to DIM_DATES)
├── OHLCV prices
├── daily_return_pct, abs_return
├── previous_close
└── Metrics: volume, intraday_range

FCT_PRICE_MOVEMENTS (daily grain)
├── movement_id (SK)
├── stock_id (FK)
├── date (FK)
├── Moving Averages: MA_7DAY, MA_30DAY, MA_90DAY
├── volatility_30day (std dev)
└── price_vs_ma30 (ABOVE/BELOW/AT)
```

**Dimension Tables**:
```
DIM_STOCKS (one row per stock)
├── stock_id (PK)
├── symbol
├── company_name, sector, market_cap
├── exchange, industry
└── market_cap_category (LARGE/MID/SMALL/MICRO)

DIM_DATES (one row per day)
├── date_key (PK)
├── year, quarter, month, week
├── day_of_month, day_of_week
├── month_name, day_name
└── is_weekend (boolean)
```

### 4. dbt (Transformation & Orchestration)

**Responsibilities**:
- Transform raw data through medallion layers
- Implement data quality tests
- Generate documentation
- Manage data lineage

**Workflows**:
```
Bronze → Silver (cleaning)
├── Remove null/invalid records
├── Standardize field names
├── Calculate derived metrics
└── Run quality tests

Silver → Gold (aggregation)
├── Create fact tables
├── Create dimension tables
├── Add business logic
├── Join with lookups
└── Run integration tests
```

**Orchestration** (Future):
- Fivetran triggers dbt Cloud job after data load
- dbt job runs: `dbt run && dbt test`
- Looker Studio auto-refreshes on dbt completion

### 5. Looker Studio (Visualization)

**Connection**:
- Direct Snowflake connector to GOLD schema
- Service account with read-only ANALYTICS_ROLE

**Dashboards**:
1. **Price Tracker**
   - Daily price chart, moving averages
   - Support/resistance levels
   - Volume analysis

2. **Returns Analysis**
   - Daily/weekly/monthly returns
   - Return distribution (histogram)
   - Best/worst performing days

3. **Market Overview**
   - Sector performance heatmap
   - Top gainers/losers
   - Market-wide statistics

4. **Volatility Heatmap**
   - 30-day volatility by stock
   - Volatility trends
   - Correlation matrix

5. **Operational Health**
   - Data freshness indicators
   - Record counts by symbol
   - Sync success/failure status

## Data Quality & Testing

### dbt Tests
- **Generic**: Not null, unique, relationships
- **Custom**: Positive prices, reasonable returns, bounds checks
- **Freshness**: Source data recency (warning if >24h old)

### Monitoring
- dbt Great Expectations (optional future)
- Snowflake data quality rules
- Looker Studio anomaly detection

## Security & Access Control

### Snowflake Roles
```
ACCOUNTADMIN
└── Warehouse/Database setup

ANALYTICS_ROLE
└── dbt user & Looker Studio
    ├── Usage on COMPUTE_WH
    ├── Select on all tables
    ├── Create in Silver/Gold
    └── Read Bronze
```

### Credentials
- Fivetran: API key (Alpha Vantage)
- dbt: Snowflake username/password (in profiles.yml, gitignore)
- Looker Studio: Service account with read-only access

## Cost Optimization

### Snowflake
- **Warehouse**: XSMALL (1 credit/hour) for dev
- **Suspension**: Auto-suspend after 5 min of idle
- **Storage**: ~10-50 GB/year for 2yr stock data

### Fivetran
- Free tier: 1M rows ingested free/month
- Stock data: ~250-500 rows/day = ~7.5-15k rows/month
- Cost: Usually free tier sufficient

### Looker Studio
- Free for up to 100 charts
- No hosting costs (Google-hosted)

## Scaling Strategy

### Short Term (Pilot)
- 20 stocks, 2 years history
- Daily refresh, no intra-day
- dbt run < 2 minutes

### Medium Term (Production)
- 100+ stocks, 5 years history
- Add sector/market data
- Weekly aggregations

### Long Term (Enterprise)
- Real-time intra-day updates
- Multiple data sources (IEX, Yahoo Finance)
- Advanced analytics (ML models)
- Multi-cluster Snowflake setup
