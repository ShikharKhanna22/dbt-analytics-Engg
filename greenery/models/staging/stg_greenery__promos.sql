{{
    config(
        materialized = 'view'
        , unique_key = 'promo_guid'
    )
}}

with promos_source as (
    select * from {{ source('src_greenery', 'promos')}}
)

, renamed_casted as (
    select
        promo_id as promo_guid
        , discount
        , status
    from promos_source
)

select * from renamed_casted