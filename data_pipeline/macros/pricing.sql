{% macro discounted_amount(extended_price, discount_percentage) %}
    {{ extended_price }} * (1 - {{ discount_percentage }})
{% endmacro %}
