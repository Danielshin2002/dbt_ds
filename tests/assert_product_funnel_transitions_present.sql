-- This test supports product funnel analysis by confirming that staged data
-- contains customer purchases with a next-order product transition.

with customer_orders as (

    select
        customer_id,
        order_id,
        ordered_at,
        row_number() over (
            partition by customer_id
            order by ordered_at, order_id
        ) as customer_order_number

    from {{ ref('stg_orders') }}

),

order_products as (

    select distinct
        customer_orders.customer_id,
        customer_orders.order_id,
        customer_orders.customer_order_number,
        items.sku as product_sku,
        products.product_type

    from customer_orders
    inner join {{ ref('stg_items') }} as items
        on customer_orders.order_id = items.order_id
    inner join {{ ref('stg_products') }} as products
        on items.sku = products.sku

),

product_transitions as (

    select
        previous_order_products.customer_id,
        previous_order_products.product_sku as previous_product_sku,
        previous_order_products.product_type as previous_product_type,
        next_order_products.product_sku as next_product_sku,
        next_order_products.product_type as next_product_type

    from order_products as previous_order_products
    inner join order_products as next_order_products
        on previous_order_products.customer_id = next_order_products.customer_id
        and previous_order_products.customer_order_number + 1
            = next_order_products.customer_order_number

),

validation as (

    select
        count(*) as transition_count

    from product_transitions

)

select
    'No customer product-to-next-order transitions were found' as failure_reason

from validation
where transition_count = 0
