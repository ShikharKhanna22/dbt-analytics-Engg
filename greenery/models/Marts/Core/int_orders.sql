{{
    config(
        materialized = 'table'
    )
}}


select 
  user_id
  , count(distinct order_guid) orders_count
  , min(created_at) first_order_timestamp_utc
  , max(created_at) last_order_timestamp_utc
  , avg(order_cost) avg_order_cost
  , sum(order_total) lifetime_order_amount
  , sum(case when status = 'shipped' then 1 else 0 end)  shipped_count
  , sum(case when status = 'preparing' then 1 else 0 end)  preparing_count
  , sum(case when status = 'delivered' then 1 else 0 end)  delivered_count
  FROM {{ ref('greenery', 'stg_greenery__orders') }}
  group by 1