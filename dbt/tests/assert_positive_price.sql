-- Ensure all prices in fct_daily_returns are positive
select
    *
from {{ ref('fct_daily_returns') }}
where close_price <= 0
