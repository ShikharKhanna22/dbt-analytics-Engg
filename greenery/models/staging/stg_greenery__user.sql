{{
    config(
        materialized = 'view'
        , unique_key = 'user_guid'
    )
}}

with user_source as (
    select * from {{ source('src_greenery', 'users')}}
)

, renamed_casted as (
    select
        user_id as user_guid
        , first_name
        , last_name
        , email
        , phone_number
        , created_at
        , updated_at
        , address_id
    from user_source
)

select * from renamed_casted