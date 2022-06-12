{{
    config(
        materialized = 'view'
        , unique_key = 'address_guid'
    )
}}

with address_source as (
    select * from {{ source('src_greenery', 'addresses')}}
)

, renamed_casted as (
    select
        address_id as address_guid
        , address as street_address
        , lpad(zipcode::varchar,5,'0') as zip_code
        , state
        , country
    from address_source
)

select * from renamed_casted