{% macro session_event_type() %}

    {% set event_types = ["page_view", "add_to_cart"] %}

    {% for event_type in event_types %}
    ,sum(case when event_type = '{{event_type}}' then 1 else 0 end) as {{event_type}}
    
    {% endfor %}

{% endmacro %}