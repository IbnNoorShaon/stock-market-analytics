-- Gold layer: Fact table for daily returns and price metrics
with stock_prices as (
    select * from {{ ref('stg_stock_prices') }}
),

stocks as (
    select * from {{ ref('dim_stocks') }}
),

returns as (
    select
        sp.symbol,
        sp.date,
        sp.open_price,
        sp.high_price,
        sp.low_price,
        sp.close_price,
        sp.volume,
        sp.daily_return_pct,
        lag(sp.close_price) over (partition by sp.symbol order by sp.date) as previous_close,
        ((sp.close_price - lag(sp.close_price) over (partition by sp.symbol order by sp.date)) /
         lag(sp.close_price) over (partition by sp.symbol order by sp.date) * 100) as daily_return_pct_adjusted,
        st.stock_id,
        row_number() over (partition by sp.symbol order by sp.date desc) as recency_rank
    from stock_prices sp
    left join stocks st on sp.symbol = st.symbol
)

select
    {{ dbt_utils.generate_surrogate_key(['stock_id', 'date']) }} as return_id,
    stock_id,
    symbol,
    date,
    open_price,
    high_price,
    low_price,
    close_price,
    volume,
    daily_return_pct,
    daily_return_pct_adjusted,
    previous_close,
    (high_price - low_price) as intraday_range,
    abs(daily_return_pct) as abs_return,
    current_timestamp() as dbt_created_at
from returns
where recency_rank <= 250  -- Keep last year of data
