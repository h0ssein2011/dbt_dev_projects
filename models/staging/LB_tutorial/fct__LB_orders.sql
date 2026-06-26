{{
    config(
        materialized='table'
    )
}}

with orders as (

    select
        order_id
        , company_id
        , employee_id
        , created_at
        , order_total
    from {{ ref('stg__LB_orders') }}

)

, payment_attempts as (

    select
        attempt_id
        , order_id
        , employee_id
        , attempted_at
        , status
        , amount_captured
    from {{ ref('stg__LB_payment_attempts') }}

)

, payment_metrics_by_order as (

    select
        order_id
        , count(*) as total_payment_attempts
        , countif(status = 'failed') as total_failed_attempts
        , countif(status = 'declined_by_bank') as total_declined_attempts
        , sum(amount_captured) as total_amount_captured
        , logical_or(status = 'completed') as is_payment_successful
        , min(if(status = 'completed', attempted_at, null)) as first_successful_payment_at
    from payment_attempts as pa
    group by order_id

)

, orders_with_payments as (

    select
        o.order_id
        , o.company_id
        , o.employee_id
        , o.created_at
        , o.order_total
        , date(o.created_at) as order_date
        , date_trunc(date(o.created_at), week(monday)) as order_week
        , date_trunc(date(o.created_at), month) as order_month
        , coalesce(pmo.total_payment_attempts, 0) as total_payment_attempts
        , coalesce(pmo.total_failed_attempts, 0) as total_failed_attempts
        , coalesce(pmo.total_declined_attempts, 0) as total_declined_attempts
        , coalesce(pmo.total_amount_captured, 0) as total_amount_captured
        , coalesce(pmo.is_payment_successful, false) as is_payment_successful
        , pmo.first_successful_payment_at
    from orders as o
    left join payment_metrics_by_order as pmo
        on o.order_id = pmo.order_id

)

, orders_with_retention_metrics as (

    select
        owp.order_id
        , owp.company_id
        , owp.employee_id
        , owp.created_at
        , owp.order_total
        , owp.order_date
        , owp.order_week
        , owp.order_month
        , owp.total_payment_attempts
        , owp.total_failed_attempts
        , owp.total_declined_attempts
        , owp.total_amount_captured
        , owp.is_payment_successful
        , owp.first_successful_payment_at
        , lag(
            if(
                owp.is_payment_successful
                , owp.order_date
                , null
            )
        ) over (
            partition by owp.employee_id
            order by owp.created_at
            , owp.order_id
        ) as employee_last_successful_order_date
        , lag(
            if(
                owp.is_payment_successful
                , owp.order_date
                , null
            )
        ) over (
            partition by owp.company_id
            order by owp.created_at
            , owp.order_id
        ) as company_last_successful_order_date
    from orders_with_payments as owp

)

, final as (

    select
        owrm.order_id
        , owrm.company_id
        , owrm.employee_id
        , owrm.created_at as order_created_at
        , owrm.order_date
        , owrm.order_week
        , owrm.order_month
        , owrm.order_total
        , owrm.total_payment_attempts
        , owrm.total_failed_attempts
        , owrm.total_declined_attempts
        , owrm.total_amount_captured
        , owrm.is_payment_successful
        , owrm.first_successful_payment_at
        , if(
            owrm.is_payment_successful
            and owrm.employee_last_successful_order_date is not null
            , date_diff(owrm.order_date, owrm.employee_last_successful_order_date, day)
            , null
        ) as days_since_employee_last_successful_order
        , if(
            owrm.is_payment_successful
            and owrm.company_last_successful_order_date is not null
            , date_diff(owrm.order_date, owrm.company_last_successful_order_date, day)
            , null
        ) as days_since_company_last_successful_order
    from orders_with_retention_metrics as owrm

)

select * from final
