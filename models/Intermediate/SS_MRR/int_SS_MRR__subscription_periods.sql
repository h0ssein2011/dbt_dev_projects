{{
    config(materialized='table')
    }}

with source as (
 select *
 from {{ source('Food_Delivery_proj', 'stg_SS_MRR__raw_subscriptions') }}
)
SELECT
from source