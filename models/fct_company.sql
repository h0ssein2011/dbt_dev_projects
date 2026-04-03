{{
  config(
    materialized='table'
  )
}}

with company as (
    select 
        admin_id,
        country_code,
        name as company_name,
        date(created_at) as signup_date,
        date(date_trunc(created_at , week(monday))) as signup_week
    from {{ ref('stg_company') }}
),

company_orders as (
    select 
        o.admin_id,
        sum(case when ot.state = 'finished' and date(o.created_at) >= date_sub(current_date(), interval 90 day) then ot.revenue else 0 end) as revenue_last_90d,
        count(distinct case when date(o.created_at) >= date_trunc(date_sub(current_date(), interval 1 week), week(monday)) 
            and date(o.created_at) < date_trunc(current_date(), week(monday)) then o.order_id end) as orders_last_week,
        count(distinct case when date(o.created_at) >= date_sub(current_date(), interval 30 day) then o.order_id end) as orders_last_30d,
        count(distinct case when date(o.created_at) >= date_sub(current_date(), interval 60 day) and date(o.created_at) < date_sub(current_date(), interval 30 day) 
                then o.order_id end) as orders_30_to_60d_ago,

    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_orders_try') }} ot on o.order_id = ot.order_id
    group by 1
),

company_audits as (
    select 
        admin_id,
        max(case when date(created_at) >= date_trunc(date_sub(current_date(), interval 1 week), week(monday)) 
                 and date(created_at) < date_trunc(current_date(), week(monday)) then 1 else 0 end) as had_update_last_week,
        max(case when field = 'contact info' 
                 and date(created_at) >= date_trunc(date_sub(current_date(), interval 1 week), week(monday)) 
                 and date(created_at) < date_trunc(current_date(), week(monday)) then 1 else 0 end) as had_contact_update_last_week
    from {{ ref('stg_company_audit_log') }}
    group by 1
),

joined as (
    select 
        c.*,
        coalesce(ow.revenue_last_90d, 0) as revenue_last_90d,
        coalesce(ow.orders_last_week, 0) as orders_last_week,
        coalesce(ow.orders_last_30d, 0) as orders_last_30d,
        coalesce(ow.orders_30_to_60d_ago, 0) as orders_30_to_60d_ago,
        coalesce(aw.had_update_last_week, 0) as had_update_last_week,
        coalesce(aw.had_contact_update_last_week, 0) as had_contact_update_last_week
    from company c
    left join company_orders ow on c.admin_id = ow.admin_id
    left join company_audits aw on c.admin_id = aw.admin_id
)

select 
    *,
    case 
        when percent_rank() over (order by revenue_last_90d desc) <= 0.10 then 'Top 10%'
        when percent_rank() over (order by revenue_last_90d desc) <= 0.60 then 'Middle 50%'
        else 'Bottom 40%' end as revenue_tier_90d
from joined