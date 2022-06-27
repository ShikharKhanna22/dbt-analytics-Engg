
{{
    config(materialized = 'table')
}}

with product_funnel as (
select product_id, 
sum(page_view) as page_view,
sum(add_to_cart) as add_to_cart,
sum(checkout) as purchases
from {{ ref('greenery', 'int_session_funnel') }}  
group by 1 )

select * from product_funnel ORDER BY "purchases" desc