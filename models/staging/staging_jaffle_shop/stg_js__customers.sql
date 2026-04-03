{{
    config(
        materialized='view'
    )
}}

with customers as (
    select id as customer_id,
    name as customer_name
    from {{ source('dbt_tutorial', 'customers') }}
)
select *
from customers