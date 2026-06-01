-- ============================================================================
-- Bronze Schema: Raw Data Tables (Created by Fivetran)
-- ============================================================================
-- These tables will be populated by Fivetran connector
-- Run this as ACCOUNTADMIN or ANALYTICS_ROLE
-- ============================================================================

use warehouse COMPUTE_WH;
use database STOCK_ANALYTICS;
use schema BRONZE;

-- Create table for daily stock prices (Fivetran will populate this)
create table if not exists RAW_STOCKS_DAILY (
  SYMBOL varchar(10) not null,
  DATE date not null,
  OPEN_PRICE float,
  HIGH_PRICE float,
  LOW_PRICE float,
  CLOSE_PRICE float,
  VOLUME number,
  _FIVETRAN_SYNCED timestamp,
  _FIVETRAN_ID varchar(255),
  _FIVETRAN_DELETED boolean default false,
  constraint pk_raw_daily unique (SYMBOL, DATE)
)
comment = 'Daily stock price data from Alpha Vantage (via Fivetran)';

-- Create table for stock metadata (Fivetran will populate this)
create table if not exists RAW_STOCKS_INFO (
  SYMBOL varchar(10) not null,
  NAME varchar(255),
  SECTOR varchar(100),
  MARKET_CAP number,
  _FIVETRAN_SYNCED timestamp,
  _FIVETRAN_ID varchar(255),
  _FIVETRAN_DELETED boolean default false,
  constraint pk_raw_info primary key (SYMBOL)
)
comment = 'Stock metadata from Alpha Vantage (via Fivetran)';

-- Set table ownership
alter table RAW_STOCKS_DAILY owner to role ANALYTICS_ROLE;
alter table RAW_STOCKS_INFO owner to role ANALYTICS_ROLE;

select 'Bronze schema created successfully!' as status;
