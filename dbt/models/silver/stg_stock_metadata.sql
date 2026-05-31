-- Silver layer: Clean and standardize stock metadata
with raw_metadata as (
    select
        symbol,
        name,
        sector,
        market_cap,
        _fivetran_synced
    from {{ source('raw', 'raw_stocks_info') }}
)

select
    symbol,
    trim(name) as company_name,
    trim(sector) as sector,
    market_cap,
    current_timestamp() as dbt_created_at,
    _fivetran_synced
from raw_metadata
where symbol is not null
