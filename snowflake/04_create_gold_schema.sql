-- ============================================================================
-- Gold Schema: Analytics-Ready Models
-- ============================================================================
-- These are tables/views created by dbt
-- This file just sets up the schema structure and permissions
-- dbt will create the actual models
-- ============================================================================

use warehouse COMPUTE_WH;
use database STOCK_ANALYTICS;

-- Ensure schema exists
create schema if not exists GOLD
  comment = 'Business logic and analytics-ready models';

-- Grant appropriate privileges to ANALYTICS_ROLE
grant usage on schema GOLD to role ANALYTICS_ROLE;
grant create table on schema GOLD to role ANALYTICS_ROLE;
grant create view on schema GOLD to role ANALYTICS_ROLE;

-- Models that will be created by dbt:
-- FACT TABLES:
--   - fct_daily_returns (table)
--   - fct_price_movements (table)
--
-- DIMENSION TABLES:
--   - dim_stocks (table)
--   - dim_dates (table)
--
-- SEED DATA:
--   - stock_symbols (table)

-- Optional: Create summary tables for common queries
-- These can be created as views for Looker Studio to consume

select 'Gold schema created successfully! dbt will populate with models.' as status;
