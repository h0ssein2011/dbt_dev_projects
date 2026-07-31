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
-- aggregat on orders and orders try
*/

with orders as (

    select  order_id,
        admin_id,
        user_id,
        order_created_at,
        date(date_trunc(order_created_at , week(monday))) order_week,
        date(date_trunc(order_created_at , month)) order_month
    from {{ ref('stg_bht__orders') }}
)
, company as(
    select      admin_id,
        country_code,
        company_name,
        created_at
    from {{ ref('stg_bht__company') }}
)
, countires as(
    select country_code,
        country_name,
        region
    from {{ ref('stg_bht__countries') }}
)
, order_try as(
    select order_try_id,
        ot.order_id,
        ot.user_id,
        order_try_created_at,
        revenue,
        order_try_status ,
        order_created_at
    from {{ ref('stg_bht__order_try') }} ot
    join {{ ref('stg_bht__orders') }} o on ot.order_id = o.order_id
),
order_try_aggregated as (
select order_id,
    case when date(order_created_at) >= date(date_trunc(date_sub(current_date() , interval 1 week ), week(monday)))
        and date(order_created_at) < date(date_trunc(current_date(), week(monday))) then 1 else 0 end as is_last_week,
        case when order_try_status = 'finished' then 1 else 0 end as is_finished_order,
    count(order_try_id) as count_try
from order_try
group by 1,2

)



select *
from order_try_aggregated