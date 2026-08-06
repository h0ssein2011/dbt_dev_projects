{{ config(materialized='table') }}

with raw_spine as (
    {{ dbt.date_spine(
        datepart="month",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2030-01-01' as date)"
    ) }}
),

clean_months as (
    select
        -- Ensures alignment to the 1st of the month
        cast(date_month as date) as month_start
    from raw_spine
)

select
    month_start,
    extract(year from month_start) as year_val,
    extract(month from month_start) as month_val
from clean_months
