{{
  config(
    materialized='table'
  )
}}

with orders as (
    select 
        order_id,  
        admin_id, 
        user_id, 
        date(created_at) as order_date,
        date(date_trunc(created_at, week(monday))) as order_week,
        date(date_trunc(created_at, month)) as order_month
    from {{ ref('stg_orders') }}
),

countries as (
    select 
        code as country_code,
        name as country_name,
        region
    from {{ ref('stg_countries') }}
),

company as (
    select 
        admin_id,
        country_code
    from {{ ref('stg_company') }}
),

order_tries_aggregated as (
    select 
        order_id, 
        count(order_try_id) as total_tries,
        sum(case when state = 'finished' then revenue else 0 end) as revenue,
        max(case when state = 'finished' then 1 else 0 end) as is_finished
    from {{ ref('stg_orders_try') }}
    group by 1
)

select 
    o.order_id,
    o.admin_id,
    o.user_id,
    o.order_date,
    o.order_week,
    o.order_month,
    ct.country_name,
    ct.region,
    coalesce(ot.total_tries, 0) as total_tries,
    coalesce(ot.revenue, 0) as revenue,
    coalesce(ot.is_finished, 0) as is_finished
from orders o 
left join company c on o.admin_id = c.admin_id
left join countries ct on ct.country_code = c.country_code
left join order_tries_aggregated ot on o.order_id = ot.order_id
