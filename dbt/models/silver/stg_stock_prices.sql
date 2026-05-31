-- Silver layer: Clean and standardize stock price data
with raw_prices as (
    select
        symbol,
        date,
        open_price,
        high_price,
        low_price,
        close_price,
        volume,
        _fivetran_synced
    from {{ source('raw', 'raw_stocks_daily') }}
)

select
    symbol,
    date,
    open_price,
    high_price,
    low_price,
    close_price,
    volume,
    (high_price - low_price) as daily_range,
    ((close_price - open_price) / open_price * 100) as daily_return_pct,
    case
        when close_price > open_price then 'UP'
        when close_price < open_price then 'DOWN'
        else 'FLAT'
    end as price_direction,
    current_timestamp() as dbt_created_at,
    _fivetran_synced
from raw_prices
where
    close_price > 0
    and open_price > 0
    and volume >= 0
    and date >= '{{ var("start_date") }}'
