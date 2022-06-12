{{
    config(
        materialized = 'view'
    )
}}

with order_items_source as (
    select * from {{ source('src_greenery', 'order_items')}}
)

, renamed_casted as (
    select
        order_id 
        , product_id
        , quantity
    from order_items_source
)

select * from renamed_casted