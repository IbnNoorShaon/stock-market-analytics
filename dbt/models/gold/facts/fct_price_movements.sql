-- Gold layer: Price movements with rolling averages and indicators
with stock_prices as (
    select * from {{ ref('stg_stock_prices') }}
),

stocks as (
    select * from {{ ref('dim_stocks') }}
),

movements as (
    select
        sp.symbol,
        sp.date,
        sp.close_price,
        sp.volume,
        st.stock_id,
        -- 7-day moving average
        avg(sp.close_price) over (
            partition by sp.symbol
            order by sp.date
            rows between 6 preceding and current row
        ) as ma_7day,
        -- 30-day moving average
        avg(sp.close_price) over (
            partition by sp.symbol
            order by sp.date
            rows between 29 preceding and current row
        ) as ma_30day,
        -- 90-day moving average
        avg(sp.close_price) over (
            partition by sp.symbol
            order by sp.date
            rows between 89 preceding and current row
        ) as ma_90day,
        -- 30-day volatility (std dev)
        stddev(sp.daily_return_pct) over (
            partition by sp.symbol
            order by sp.date
            rows between 29 preceding and current row
        ) as volatility_30day,
        -- Price position relative to moving averages
        case
            when sp.close_price > ma_30day then 'ABOVE_MA30'
            when sp.close_price < ma_30day then 'BELOW_MA30'
            else 'AT_MA30'
        end as price_vs_ma30,
        row_number() over (partition by sp.symbol order by sp.date desc) as recency_rank
    from stock_prices sp
    left join stocks st on sp.symbol = st.symbol
)

select
    {{ dbt_utils.generate_surrogate_key(['stock_id', 'date']) }} as movement_id,
    stock_id,
    symbol,
    date,
    close_price,
    volume,
    ma_7day,
    ma_30day,
    ma_90day,
    volatility_30day,
    price_vs_ma30,
    (close_price - ma_30day) as price_deviation_from_ma30,
    current_timestamp() as dbt_created_at
from movements
where recency_rank <= 250
