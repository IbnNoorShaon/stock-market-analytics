-- Ensure daily returns are within reasonable bounds (-100% to +100%)
select
    *
from {{ ref('fct_daily_returns') }}
where daily_return_pct < -100 or daily_return_pct > 100
