{{
    config(
        materialized='table'
    )
}}

with riders as (
    select rider_id
            , city
            , vehicle_type
            , activated_date
    from {{ ref('stg_FD__riders') }}
)

select *
from riders