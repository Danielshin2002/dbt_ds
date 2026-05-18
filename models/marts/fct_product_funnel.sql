with product_transitions as (

    select * from {{ ref('int_product_funnel_transitions') }}

),

sku_transitions as (

    select
        previous_product_sku,
        previous_product_name,
        previous_product_type,
        next_product_sku,
        next_product_name,
        next_product_type,
        count(*) as transition_count,
        count(distinct customer_id) as customer_count,
        avg(days_between_orders) as avg_days_between_orders

    from product_transitions
    group by
        previous_product_sku,
        previous_product_name,
        previous_product_type,
        next_product_sku,
        next_product_name,
        next_product_type

),

final as (

    select
        previous_product_sku,
        previous_product_name,
        previous_product_type,
        next_product_sku,
        next_product_name,
        next_product_type,
        transition_count,
        customer_count,
        avg_days_between_orders,
        round(
            transition_count
            / sum(transition_count) over (partition by previous_product_sku),
            4
        ) as pct_of_previous_product_next_purchases

    from sku_transitions

)

select * from final
