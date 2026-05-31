-- Gold layer: Date dimension for time-based analysis
with date_series as (
    select
        cast(dateadd(day, seq4(), '2024-01-01') as date) as date_key
    from
        table(generate_series(0, 730))  -- 2 years of data
),

dates_with_attributes as (
    select
        date_key,
        year(date_key) as year_number,
        quarter(date_key) as quarter_number,
        month(date_key) as month_number,
        week(date_key) as week_number,
        dayofmonth(date_key) as day_of_month,
        dayofweek(date_key) as day_of_week,
        case
            when dayofweek(date_key) in (6, 7) then true
            else false
        end as is_weekend,
        to_varchar(date_key, 'YYYY-MM') as year_month,
        to_varchar(date_key, 'YYYY-Q') as year_quarter,
        monthname(date_key) as month_name,
        dayname(date_key) as day_name
    from date_series
)

select
    date_key,
    year_number,
    quarter_number,
    month_number,
    week_number,
    day_of_month,
    day_of_week,
    is_weekend,
    year_month,
    year_quarter,
    month_name,
    day_name,
    current_timestamp() as dbt_created_at
from dates_with_attributes
where date_key >= '2024-01-01'
