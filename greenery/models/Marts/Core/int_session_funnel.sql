
{{
    config(materialized = 'table')
}}



with page_view_add_cart as (
SELECT session_id, product_id
{{ session_event_type() }}
FROM {{ ref('greenery', 'stg_greenery__events') }}  
where event_type NOT IN ('checkout','package_shipped')
group by 1,2),

session_checkout as (
SELECT session_id,
sum(case when event_type = 'checkout' then 1 else 0 end) as checkout
FROM {{ ref('greenery', 'stg_greenery__events') }}  
group by 1),

session_funnel as (
select 
ac.session_id, ac.product_id, ac.page_view, ac.add_to_cart, coalesce(sc.checkout,0) as checkout
from page_view_add_cart ac
left join session_checkout sc
on ac.session_id = sc.session_id and add_to_cart <> 0 )

select * from session_funnel