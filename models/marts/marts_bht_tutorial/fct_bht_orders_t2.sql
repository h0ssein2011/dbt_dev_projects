{{
    config(
        materialized='table'
    )
}}

/*
Daily/Weekly/Monthly Dynamic of Revenue and Orders per Country, Region. Only Revenue from completed orders should be counted.
How many monthly active users do we have (at least with 1 completed order within the last 30 days) in the last week?
What is the average order try per finished order per country over the past week?
Identify regions where order volume increased or decreased by more than 20% week-over-week over the past month.

which tables are required to cover these:
- order
- company --> region
- countries --> region, country name
-- order try
-- aggregated :
    orders_try :
    - revenue per country & region
    - avg order try per country
    - last_week

     orders :
        - count Monthly active user
        - last_week
        - sum order volume weekly growth pct
*/
with company as (
    select admin_id,
        country_code,
        company_name,
        created_at
    from {{ ref('stg_bht__company') }}
)
, countries as (
select
        country_code,
        country_name,
        region
from {{ ref('stg_bht__countries') }}
)
, orders as (
select  order_id,
        admin_id,
        user_id,
        order_created_at,
        date(date_trunc(order_created_at , week(monday))) order_week,
        date(date_trunc(order_created_at , month)) order_month
from {{ ref('stg_bht__orders') }}
)
,order_try as (

    select order_try_id,
        order_id,
        user_id,
        order_try_created_at,
        case when date_trunc(date(order_try_created_at) ,week(monday)) = date_trunc(DATE_ADD(current_date, INTERVAL -7 DAY) ,week(monday)) then 1 else 0 end as is_last_week,
        revenue,
        order_try_status
    from {{ ref('stg_bht__order_try') }}
)
, orders_cohort_flag as (
    select o1.order_id
            ,o1.user_id
            ,case when o1.order_week = date_trunc( DATE_ADD(current_date, INTERVAL -7 DAY) ,week(monday) )   then 1 else 0 end as is_last_week
    from orders o1
    join orders o2 on o1.user_id = o2.user_id  and o2.order_created_at between DATE_ADD(o1.order_created_at, INTERVAL -30 DAY) and o1.order_created_at

)
select
        o.order_id,
        o.admin_id,
        o.user_id,
        c1.country_code,
        c2.region,
        o.order_created_at,
        o.order_week,
        o.order_month,
        coalesce(ocf.is_last_week,0) as is_last_week,
        case when ocf.user_id is null then 1 else 0 end as active_last_30d,
        ot.revenue,
        ot.order_try_status
from order_try ot
join orders o on ot.order_id= o.order_id
join company c1 on c1.admin_id = o.admin_id
join countries c2 on c2.country_code = c1.country_code
left join orders_cohort_flag ocf on ocf.order_id = o.order_id

