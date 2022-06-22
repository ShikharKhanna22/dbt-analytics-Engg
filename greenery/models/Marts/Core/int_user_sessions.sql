

{{
    config(
        materialized = 'table'
    )
}}

with user_sessions as (
select 
  session_id 
  , user_id
  , min(created_at) session_start
  , max(created_at) session_end
  , count(distinct product_id) products_by_session
  , count(distinct order_id) orders_by_session
  , count(distinct case when event_type = 'add_to_cart' then product_id end ) products_added_to_cart
  , count(distinct case when event_type = 'checkout' then product_id end ) checked_out_event
  , count(distinct case when event_type = 'page_view' then 1 end ) page_view_event
  , count(distinct case when event_type = 'add_to_cart' then 1 end ) add_to_cart_event
  , count(distinct case when event_type = 'checkout' then 1 end ) checkout_event
  , count(distinct case when event_type = 'package_shipped' then 1 end ) package_shipped_event

  FROM {{ ref('greenery', 'stg_greenery__events') }} 
  group by 1,2 )


select
  *
  from user_sessions
