{{ config(materialized='table') }}
with source as (

select customer_id,
        plan_id,
        start_date,
        end_date,
        status
from {{ ref('stg_ss_mrr__raw_subscriptions') }}

), spin_months as (

select month_start,
    year_val,
    month_val
 {{ ref('spine_months') }}

) , joined as (
select sm.month_start as reporting_month,
        customer_id,
        plan_id,
        status
from spin_months sm
join  source sr on sm between sr.start_date and end_date
where end_date <= date_trunc(current_date() , month)
)
select *
from joined
