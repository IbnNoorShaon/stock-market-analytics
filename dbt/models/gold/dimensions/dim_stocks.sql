-- Gold layer: Dimension table for stocks
with stock_metadata as (
    select * from {{ ref('stg_stock_metadata') }}
),

stock_list as (
    select * from {{ ref('stock_symbols') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['md.symbol']) }} as stock_id,
    md.symbol,
    md.company_name,
    md.sector,
    md.market_cap,
    sl.exchange,
    sl.industry,
    case
        when md.market_cap > 300000000000 then 'LARGE_CAP'
        when md.market_cap > 10000000000 then 'MID_CAP'
        when md.market_cap > 300000000 then 'SMALL_CAP'
        else 'MICRO_CAP'
    end as market_cap_category,
    current_timestamp() as dbt_created_at
from stock_metadata md
left join stock_list sl on md.symbol = sl.symbol
