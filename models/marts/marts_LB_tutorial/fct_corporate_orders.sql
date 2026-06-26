{{
    config(
        materialized='table'
    )
}}

/*
Revenue & Performance

What is the daily and weekly dynamic of captured revenue per region? (Only count revenue from completed payment attempts).✅ 

Which regions experienced an order volume increase or decrease of more than 20% week-over-week over the past month? 

Who are our "Whale" clients? Identify the top 5 companies by total captured revenue in the current quarter.

User Engagement & Retention
4. How many Monthly Active Employees (employees with at least 1 successful order in the last 30 days) did we have across the entire platform last week?✅ 
5. What is the rolling 30-day retention rate of companies? (e.g., If a company places an order in Month 1, do they place another order in Month 2?) ✅
6. Which companies are at "Churn Risk"? Identify companies that had more than 20 successful orders last month, but 0 orders so far this month.✅

Platform Friction (Payment Issues)
7. What is the average number of payment attempts required per successful order, broken down by country? ✅
8. What percentage of total payment attempts end in a failed or declined_by_bank status, grouped by account_tier? ✅
9. Are there specific employees abusing the system? Flag any employee_id that has accumulated more than 4 failed payment attempts on a single order.✅
10. What is the average time delay (in minutes) between an order being created (stg_orders.created_at) and its first successful payment attempt (stg_payment_attempts.attempted_at)?✅


- order table order_id level
-- payment attempt in order level

*/

with orders as  (
select order_id
    , company_id 
    , employee_id
    , created_at
    , Date(Date_trunc(created_at,DAY))  as date 
    , Date(Date_trunc(created_at ,WEEK(Monday)))  as week
    , case when date(created_at) >= Date(Date_trunc( date_add(current_date , interval -5 day) ,WEEK(Monday))) 
            and date(created_at) < Date_trunc(current_date ,WEEK(Monday)) 
                then 1 else 0 end as is_last_week
from {{ ref('stg__LB_orders') }} 
)
, attemps as (
select  attempt_id
        , order_id
        , employee_id
        , attempted_at
        , status
        , amount_captured
from {{ ref('stg__LB_payment_attempts') }}
)
, attemps_agg as (
select order_id 
    , sum(case when status ='completed' then amount_captured end) as successful_amount_captured
    , sum(case when status ='completed' then 1 end) as successful_attemp
    , sum(case when status <>'completed' then 1 end) as failed_attemp
    , max(case when status ='completed' then attempted_at end) as max_success_attemp
from attemps
group by 1
) 
, client_company  as (
    select c.company_id
        , c.country_code
        , c.company_name
        , c.account_tier
        , c.created_at as signup_date
    ,g.country_name , g.region
    from {{ ref('stg__LB_client_company') }} c 
    join {{ ref('stg__LB_geography') }} g  on c.country_code = g.country_code
)
, active_employees as (
    select o.employee_id 
        , o.order_id
        , case when date(p.attempted_at) >= date_add(current_date, interval -30 day ) then 1 else 0 end as active_employee
    from orders o  
    join attemps p on o.order_id = p.order_id
    where p.status = 'completed'
) , employee_attemps as (
    select employee_id , order_id , count(*) as failed_attemps
    from attemps 
    where status <> 'completed'
    group by 1,2
) ,
orders_attempt as (
    select o.order_id, DATE_DIFF (max_success_attemp , o.created_at , minute ) as susscess_attemps_duration
    from orders o 
    join attemps_agg a on o.order_id = a.order_id
) 
select o.*
    , coalesce(aa.successful_amount_captured,0) as successful_amount_captured
    , coalesce(aa.successful_attemp,0) as successful_attemps
    , coalesce(aa.failed_attemp,0) as failed_attemps
    , c.region
    , c.country_name
    , c.account_tier
    , coalesce(ae.active_employee,0) as active_employee
    , case when ea.failed_attemps >= 4 then 1 else 0 end as employee_abuser
    , oa.susscess_attemps_duration
from orders o 
left join attemps_agg aa on o.order_id = aa.order_id 
join client_company c on c.company_id = o.company_id
left join active_employees ae  on o.order_id = ae.order_id 
left join employee_attemps ea on o.order_id = ea.order_id 
left join orders_attempt oa on o.order_id = oa.order_id 
