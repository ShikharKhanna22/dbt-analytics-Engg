{{
    config(
        materialized = 'view'
        , unique_key = 'product_guid'
    )
}}

with products_source as (
    select * from {{ source('src_greenery', 'products')}}
)

, renamed_casted as (
    select
        product_id as product_guid
        , name
        , price
        , inventory
    from products_source
)

select * from renamed_casted