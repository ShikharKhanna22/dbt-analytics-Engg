

{{
    config(
        materialized = 'table'
    )
}}

with user_order as (
select 
  user_id
  , count(distinct order_guid) orders_count
  , min(created_at) first_order_timestamp_utc
  , max(created_at) last_order_timestamp_utc
  , avg(order_cost) avg_order_cost
  , sum(order_cost) sum_order_cost
  , avg(shipping_cost) avg_shipping_cost
  , sum(shipping_cost) sum_shipping_cost
  , sum(order_total) lifetime_order_amount
  , sum(case when status = 'shipped' then 1 else 0 end)  shipped_count
  , sum(case when status = 'preparing' then 1 else 0 end)  preparing_count
  , sum(case when status = 'delivered' then 1 else 0 end)  delivered_count
  FROM {{ ref('greenery', 'stg_greenery__orders') }}
  group by 1  ),
  
user_order_product as (
  select 
    user_id
    , count(distinct(product_id)) lifetime_product_count
    , sum(quantity) lifetime_quantity
   from {{ ref('greenery', 'stg_greenery__orders') }} orders
   left join {{ ref('greenery', 'stg_greenery__order_items') }}  items
   on orders.order_guid = items.order_id  
   group by 1   ),
   
user_order_promo as (
  select 
    user_id
    , count(promo_guid) lifetime_promo_count
    , sum(discount) lifetime_discount
   from {{ ref('greenery', 'stg_greenery__orders') }} orders
   left join {{ ref('greenery', 'stg_greenery__promos') }}  promos
   on orders.promo_id = promos.promo_guid  
   group by 1   ),

user_session_stats as (
select 
    user_id
    , count(distinct session_id) session_count
    , min(created_at) first_seen_session
    , max(created_at) last_seen_session
    , date_part('day', (max(created_at) - min(created_at))) user_tenure
    from 
	  {{ ref('greenery', 'stg_greenery__events') }} 
    group by 1   )
  
select 
  	orders.*
    , product.lifetime_product_count
    , product.lifetime_quantity
    , promo.lifetime_promo_count
    , promo.lifetime_discount
    , session_stat.session_count
    , session_stat.first_seen_session
    , session_stat.last_seen_session
    , session_stat.user_tenure
  from user_order as orders
  left join user_order_product product
  on orders.user_id = product.user_id
  left join user_order_promo promo
  on product.user_id = promo.user_id
  left join user_session_stats session_stat
  on orders.user_id = session_stat.user_id