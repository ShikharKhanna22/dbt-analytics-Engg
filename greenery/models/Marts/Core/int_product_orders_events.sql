{{
    config(   materialized = 'table'  )
}}


with product_event as (
  SELECT
  product_id
  , sum(case when event_type= 'add_to_cart' then 1 else 0 end) as session_add_to_cart
  , sum(case when event_type= 'page_view' then 1 else 0 end) as session_page_view
  from {{ ref('greenery', 'stg_greenery__events') }}  
  where event_type in ('page_view', 'add_to_cart')
  group by product_id ),
  
  product_order as (
  select
    product_guid
	, "name" as product_name
    , price as product_price
    , inventory as inventory
    , sum(quantity) as order_quantity
    , count(distinct(orders.user_id)) as user_count
    , count(distinct(order_guid)) as order_count
 from {{ ref('greenery', 'stg_greenery__products') }}   product
 left join {{ ref('greenery', 'stg_greenery__order_items') }}   order_item
 on product.product_guid = order_item.product_id
 left join {{ ref('greenery', 'stg_greenery__orders') }}   orders
 on orders.order_guid = order_item.order_id
 group by 1,2,3,4 )

select 
	orders.* 
    , events.*
from 
product_order orders
left join product_event events
on orders.product_guid = events.product_id