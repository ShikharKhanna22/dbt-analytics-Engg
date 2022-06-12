{{
    config(
        materialized = 'view'
        , unique_key = 'event_guid'
    )
}}

with events_source as (
    select * from {{ source('src_greenery', 'events')}}
)

, renamed_casted as (
    select
        event_id as event_guid
        , session_id
        , user_id
        , page_url
        , created_at
        , event_type
        , order_id
        , product_id
    from events_source
)

select * from renamed_casted