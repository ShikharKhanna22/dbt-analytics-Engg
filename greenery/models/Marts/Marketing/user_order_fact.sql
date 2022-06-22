
{{
    config(   materialized = 'table'  )
}}

with user_detail as (
  select * from {{ ref('greenery', 'stg_greenery__user') }} 
 ) ,
 
user_address as (
 	select * from {{ ref('greenery', 'stg_greenery__address') }} 
 ),

user_order as (
select 
  user_id
  , orders_count
  , round(sum_order_cost) as sum_order_cost
  , round(sum_shipping_cost) as sum_shipping_cost
  , lifetime_product_count
  , round(lifetime_order_amount) as lifetime_order_amount
  , lifetime_discount
  , session_count
  , user_tenure
 from {{ ref('greenery', 'int_user_order') }}  )
    
  select
  first_name
  , last_name
  , email
  , phone_number
  , zip_code
  , state
  , country
  , orders_count
  , round(sum_order_cost) as sum_order_cost
  , round(sum_shipping_cost) as sum_shipping_cost
  , lifetime_product_count
  , round(lifetime_order_amount) as lifetime_order_amount
  , lifetime_discount
  , session_count
  , user_tenure
    from user_order orders
    left join user_detail users
    on orders.user_id = users.user_guid
    left join user_address address
    on users.address_id = address.address_guid