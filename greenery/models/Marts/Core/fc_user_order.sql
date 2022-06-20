

{{
    config(
        materialized = 'table'
    )
}}

with user_order as (
  select 
  *
  FROM {{ ref('greenery', 'int_orders') }}  ),
  
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
   group by 1   )
  
select 
  	orders.*
    , product.lifetime_product_count
    , product.lifetime_quantity
    , promo.lifetime_promo_count
    , promo.lifetime_discount
  from user_order as orders
  left join user_order_product product
  on orders.user_id = product.user_id
  left join user_order_promo promo
  on product.user_id = promo.user_id