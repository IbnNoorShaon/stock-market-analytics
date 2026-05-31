-- ============================================================================
-- Snowflake Setup: Warehouse, Databases, and Roles
-- ============================================================================
-- Run this as ACCOUNTADMIN role
-- ============================================================================

-- Create Warehouse
create warehouse if not exists COMPUTE_WH
  warehouse_size = XSMALL
  auto_suspend = 300
  auto_resume = true
  initially_suspended = true
  comment = 'Development & analytics compute warehouse';

-- Create Analytics Database
create database if not exists STOCK_ANALYTICS
  comment = 'Stock market analytics warehouse';

-- Create Schemas
create schema if not exists STOCK_ANALYTICS.BRONZE
  comment = 'Raw data from Fivetran';

create schema if not exists STOCK_ANALYTICS.SILVER
  comment = 'Cleaned and transformed staging data';

create schema if not exists STOCK_ANALYTICS.GOLD
  comment = 'Business logic and analytics-ready models';

-- Create Role for Analytics
create role if not exists ANALYTICS_ROLE
  comment = 'Role for analytics users and dbt';

-- Grant Warehouse Privileges
grant usage on warehouse COMPUTE_WH to role ANALYTICS_ROLE;
grant operate on warehouse COMPUTE_WH to role ANALYTICS_ROLE;

-- Grant Database Privileges
grant usage on database STOCK_ANALYTICS to role ANALYTICS_ROLE;
grant create schema on database STOCK_ANALYTICS to role ANALYTICS_ROLE;

-- Grant Schema Privileges
grant usage on all schemas in database STOCK_ANALYTICS to role ANALYTICS_ROLE;
grant create table on all schemas in database STOCK_ANALYTICS to role ANALYTICS_ROLE;
grant create view on all schemas in database STOCK_ANALYTICS to role ANALYTICS_ROLE;

-- Grant Table Privileges for existing tables
grant select on all tables in database STOCK_ANALYTICS to role ANALYTICS_ROLE;

-- Create User for dbt (optional - can use existing user)
-- create user if not exists dbt_user
--   password = '...'
--   default_warehouse = COMPUTE_WH
--   default_database = STOCK_ANALYTICS
--   default_role = ANALYTICS_ROLE;
--
-- grant role ANALYTICS_ROLE to user dbt_user;

-- Set default context for subsequent commands
use role accountadmin;
use warehouse COMPUTE_WH;
use database STOCK_ANALYTICS;

select 'Snowflake setup complete!' as status;
