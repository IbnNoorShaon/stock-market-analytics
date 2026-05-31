# Looker Studio Setup Guide

## Overview

Looker Studio will connect directly to Snowflake's GOLD schema to create interactive dashboards for stock market analysis.

## Prerequisites

1. ✅ Google account (Looker Studio is free)
2. ✅ Snowflake GOLD schema populated by dbt (see dbt/README.md)
3. ✅ dbt models successfully created:
   - `FCT_DAILY_RETURNS`
   - `FCT_PRICE_MOVEMENTS`
   - `DIM_STOCKS`
   - `DIM_DATES`

## Step 1: Connect Looker Studio to Snowflake

### 1. Access Looker Studio
- Visit https://looker.studio/ (sign in with Google account)
- Click **Create** → **Report**

### 2. Add Data Source

1. Click **Resource** → **Manage added data sources**
2. Click **Create new data source**
3. Select **Snowflake** from connector list
4. Click **Connect**

### 3. Configure Snowflake Connection

Fill in your Snowflake credentials:

| Field | Value |
|-------|-------|
| Project ID | `[Your Snowflake Account ID]` e.g., `xy12345.us-east-1` |
| Database | `STOCK_ANALYTICS` |
| Warehouse | `COMPUTE_WH` |
| Username | [Your Snowflake username] |
| Password | [Your Snowflake password] |

Click **Authenticate** (test the connection)

### 4. Create Data Source

1. After authentication, select **Database**: `STOCK_ANALYTICS`
2. Select **Schema**: `GOLD`
3. Select **Table**: `FCT_DAILY_RETURNS` (start with this)
4. Click **Create Data Source**
5. Name it: `Stock Daily Returns`

Repeat for other tables:
- `FCT_PRICE_MOVEMENTS` → "Stock Price Movements"
- `DIM_STOCKS` → "Stock Dimensions"
- `DIM_DATES` → "Date Dimensions"

## Step 2: Create Base Dashboard

### Dashboard Structure

Create a new report with these sections:

```
1. Header
   - Title: "Stock Market Analytics"
   - Date range selector (last 1 year)

2. Market Overview
   - KPIs: # of stocks tracked, date range
   - Sector heatmap (if sector data available)

3. Individual Stock Analysis
   - Price chart (OHLC)
   - Returns chart
   - Moving averages

4. Volatility & Risk
   - Volatility comparison
   - Correlation matrix

5. Performance Metrics
   - Top gainers/losers (this week, month, year)
   - Average returns by sector
```

## Step 3: Build Dashboard Components

### Component 1: Price Tracker

**Chart Type**: Time Series (Line/Candlestick)

**Data Source**: `Stock Daily Returns`

**Dimensions**:
- X-axis: `DATE` (Dimension)
- Series: `SYMBOL` (Dimension)

**Metrics**:
- Primary: `CLOSE_PRICE` (Average)

**Filters**:
- `SYMBOL`: Multi-select dropdown
- `DATE`: Date range picker

**Instructions**:
1. In report, click **Insert** → **Chart**
2. Select **Time Series** chart
3. Set Data Source: `Stock Daily Returns`
4. Drag `DATE` to Dimension
5. Drag `SYMBOL` to Dimension (breakout)
6. Drag `CLOSE_PRICE` to Metrics
7. Add filters for symbol selection

### Component 2: Returns Analysis

**Chart Type**: Column Chart

**Data Source**: `Stock Daily Returns`

**Dimensions**:
- X-axis: `SYMBOL`

**Metrics**:
- Primary: `DAILY_RETURN_PCT` (Average)
- Secondary: `ABS_RETURN` (Standard Deviation)

**Filters**:
- `DATE`: Last 30 days

**Instructions**:
1. Insert Column Chart
2. Set Data Source: `Stock Daily Returns`
3. Drag `SYMBOL` to Dimension
4. Drag `DAILY_RETURN_PCT` to Metrics
5. Add date filter: Last 30 days

### Component 3: Moving Averages

**Chart Type**: Time Series (Line)

**Data Source**: `Stock Price Movements`

**Dimensions**:
- X-axis: `DATE`

**Metrics**:
- `CLOSE_PRICE`
- `MA_7DAY`
- `MA_30DAY`
- `MA_90DAY`

**Instructions**:
1. Insert Time Series chart
2. Set Data Source: `Stock Price Movements`
3. Add multiple metric lines
4. Color code: Price (blue), MA-7 (green), MA-30 (orange), MA-90 (red)

### Component 4: Volatility Comparison

**Chart Type**: Bar Chart (Horizontal)

**Data Source**: `Stock Price Movements`

**Dimensions**:
- Y-axis: `SYMBOL`

**Metrics**:
- Primary: `VOLATILITY_30DAY` (Average)

**Filters**:
- `DATE`: Last 90 days

**Instructions**:
1. Insert Bar Chart
2. Set Data Source: `Stock Price Movements`
3. Sort by volatility descending
4. Add conditional formatting (red for high volatility)

### Component 5: Top Gainers/Losers

**Chart Type**: Scorecard + Table

**Data Source**: `Stock Daily Returns`

**For Gainers**:
```sql
SELECT SYMBOL, DAILY_RETURN_PCT
WHERE DAILY_RETURN_PCT > 0
ORDER BY DAILY_RETURN_PCT DESC
LIMIT 5
```

**For Losers**:
```sql
SELECT SYMBOL, DAILY_RETURN_PCT
WHERE DAILY_RETURN_PCT < 0
ORDER BY DAILY_RETURN_PCT ASC
LIMIT 5
```

## Step 4: Add Interactivity

### Filters (Top of Dashboard)

1. **Symbol Filter**
   - Type: Dropdown (multi-select)
   - Data source: `DIM_STOCKS`
   - Apply to: All charts

2. **Date Range Filter**
   - Type: Date range picker
   - Default: Last 1 year
   - Apply to: All charts

3. **Sector Filter** (if data available)
   - Type: Dropdown
   - Data source: `DIM_STOCKS`
   - Filters to: `SECTOR` dimension

### Dynamic Formatting

- **High volatility** (>5%): Red background
- **Positive returns** (>0%): Green text
- **Negative returns** (<0%): Red text
- **MA crossover**: Icon indicators

## Step 5: Publish Dashboard

1. Click **Share** (top right)
2. Set permissions:
   - **Viewer access**: Share with others
   - **Editor access**: For team members

3. Get shareable link or embed code

## Step 6: Set Up Auto-Refresh

1. Click **File** → **Report Settings**
2. Under "Data freshness":
   - Set refresh interval: **Daily** (automatic)
   - Or: **Every 4 hours** (if intra-day updates)

3. Enable "Notify on data updates" (optional)

## Example Dashboard Queries

### YTD Performance by Symbol

```sql
SELECT
    SYMBOL,
    AVG(DAILY_RETURN_PCT) as avg_daily_return,
    STDDEV(DAILY_RETURN_PCT) as volatility,
    COUNT(*) as trading_days
FROM FCT_DAILY_RETURNS
WHERE YEAR(DATE) = YEAR(CURRENT_DATE())
GROUP BY SYMBOL
ORDER BY avg_daily_return DESC
```

### Best & Worst Days

```sql
SELECT
    DATE,
    SYMBOL,
    DAILY_RETURN_PCT,
    CLOSE_PRICE
FROM FCT_DAILY_RETURNS
WHERE DAILY_RETURN_PCT > 5 OR DAILY_RETURN_PCT < -5
ORDER BY DATE DESC
```

### Volatility by Sector

```sql
SELECT
    SECTOR,
    AVG(VOLATILITY_30DAY) as avg_volatility,
    COUNT(DISTINCT SYMBOL) as num_stocks
FROM FCT_PRICE_MOVEMENTS fp
JOIN DIM_STOCKS ds on fp.STOCK_ID = ds.STOCK_ID
WHERE DATE >= CURRENT_DATE() - INTERVAL '90 days'
GROUP BY SECTOR
ORDER BY avg_volatility DESC
```

## Dashboard Refresh Schedule

| Frequency | Use Case |
|-----------|----------|
| **Hourly** | Real-time trading dashboards (requires intra-day data) |
| **Daily (@ 5:00 PM EST)** | End-of-day analysis (recommended) |
| **Weekly** | Strategic review dashboards |
| **Manual** | Ad-hoc analysis (click refresh button) |

**Recommendation**: Set to daily @ 5:00 PM EST (30 min after market close + Fivetran sync)

## Troubleshooting

### Issue: "Permission denied" when connecting
- Check Snowflake user has read access to GOLD schema
- Verify user role has SELECT privileges:
  ```sql
  grant select on all tables in schema gold to role analytics_role;
  ```

### Issue: "No data" in charts
- Verify dbt models exist in GOLD schema:
  ```sql
  show tables in stock_analytics.gold;
  ```
- Check data was populated:
  ```sql
  select count(*) from stock_analytics.gold.fct_daily_returns;
  ```

### Issue: "Query timeout"
- Snowflake query is too complex
- Solution: Add WHERE clause to filter date range (smaller result set)
- Or: Create materialized tables in dbt instead of views

### Issue: "Metrics not refreshing"
- Check Snowflake data is being updated by Fivetran
- Verify dbt job completed successfully
- Manually refresh Looker Studio: Click **Refresh** button

## Advanced Features

### Conditional Formatting

```
Rule: IF DAILY_RETURN_PCT > 3% THEN Green
Rule: IF DAILY_RETURN_PCT < -3% THEN Red
Rule: IF VOLATILITY_30DAY > 5% THEN Yellow
```

### Custom Metrics (Looker Formula)

```javascript
// Sharpe Ratio (example)
AVG(DAILY_RETURN_PCT) / STDDEV(DAILY_RETURN_PCT)

// Win Rate
COUNT(IF(DAILY_RETURN_PCT > 0, 1)) / COUNT(*) * 100
```

### Embedded Charts

Share individual charts on websites or wikis:
1. Click chart → **More options** → **Embed chart**
2. Copy embed code
3. Paste into website HTML

## Best Practices

1. **Keep dashboards clean**
   - 5-7 charts per page maximum
   - Clear titles and descriptions

2. **Use filters effectively**
   - Symbol multi-select (don't hardcode stocks)
   - Date range filters (relative, not fixed dates)

3. **Monitor performance**
   - Add "Last refresh time" indicator
   - Monitor query execution time

4. **Version control**
   - Save dashboard snapshots before major changes
   - Document filter defaults and business logic

5. **Security**
   - Don't share Snowflake credentials in reports
   - Use service account with read-only access
   - Implement row-level security if needed

## Resources

- [Looker Studio Help Center](https://support.google.com/looker-studio)
- [Looker Studio & Snowflake Guide](https://www.snowflake.com/en/data-cloud/integrations/partners/looker/)
- [Looker Studio Chart Types](https://support.google.com/looker-studio/answer/11299446)
- [dbt Metrics Documentation](https://docs.getdbt.com/docs/build/metrics)

## Next Steps

After dashboard creation:

1. ✅ Share dashboard link with stakeholders
2. ✅ Set up automated refresh schedule
3. ✅ Document key business logic
4. ✅ Create user guide for dashboard users
5. 📈 Iterate on visualizations based on feedback
