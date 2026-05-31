-- ============================================================================
-- Silver Schema: Staging/Cleaning Layer
-- ============================================================================
-- These are views created by dbt that clean bronze data
-- This file just sets up the schema structure
-- dbt will create the actual views/tables
-- ============================================================================

use warehouse COMPUTE_WH;
use database STOCK_ANALYTICS;

-- Ensure schema exists
create schema if not exists SILVER
  comment = 'Cleaned and validated data';

-- Grant appropriate privileges
grant usage on schema SILVER to role ANALYTICS_ROLE;
grant create table on schema SILVER to role ANALYTICS_ROLE;
grant create view on schema SILVER to role ANALYTICS_ROLE;

-- Staging tables and views will be created by dbt models:
-- - stg_stock_prices (view)
-- - stg_stock_metadata (view)

select 'Silver schema created successfully! dbt will populate with views.' as status;
