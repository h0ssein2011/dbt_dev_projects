{{
    config(
        materialized='table'
    )
}}

/*
5. What is the rolling 30-day retention rate of companies? (e.g., If a company places an order in Month 1, do they place another order in Month 2?)✅
6. Which companies are at "Churn Risk"? Identify companies that had more than 20 successful orders last month, but 0 orders so far this month. ✅
*/

with companies as (
    select company_id,
        country_code,
        company_name,
        account_tier,
        created_at
    from {{ ref('stg__LB_client_company') }}
),
attemps as (
select order_id
    , status
    , amount_captured
from {{ ref('stg__LB_payment_attempts') }}
)
, orders as  (
select order_id
    , company_id
    , employee_id
    , Date(Date_trunc(created_at,month))  as reporting_month
    ,DATE_DIFF(Date(created_at) , LAG(Date(created_at)) over(partition by company_id order by created_at),Day ) as days_diff
from {{ ref('stg__LB_orders') }}
),
orders_agg as (
    select o.company_id
    , o.reporting_month
    , count(o.order_id) as order_count
    , min(days_diff) as min_days_diff
    from orders o
    join attemps  a on a.order_id = o.order_id
    where a.status ='completed'
    group by 1,2
),
Churn_status as (
    select company_id
    , case when reporting_month = Date(Date_trunc(current_date,month)) and order_count >=20
            then 1 else 0 end as active_this_month
    , case when reporting_month = Date(Date_trunc(date_add(current_date, interval -29 day),month)) and order_count >=20
     then 1 else 0 end as active_last_month
    , min_days_diff
    from orders_agg
    group by 1,2,3,4
)

select c.company_id
        , c.country_code
        , c.company_name
        , c.account_tier
        , date(c.created_at) as signup_date
        , case when active_last_month = 1 and active_this_month = 0 then 1 else 0 end as churn_risk
        , case when min_days_diff is not null and min_days_diff <= 30 then 1 else 0 end as retained
from companies c
join Churn_status cs on c.company_id = cs.company_id



