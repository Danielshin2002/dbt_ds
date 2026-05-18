with product_supply_costs as (

    select
        sku,
        sum(supply_cost) as total_supply_cost

    from {{ ref('stg_supplies') }}
    group by sku

),

sales as (

    select
        orders.store_id,
        stores.store_name,
        stores.tax_rate,
        orders.order_id,
        orders.customer_id,
        orders.ordered_at,
        orders.order_date,
        items.item_id,
        items.sku,
        products.product_name,
        products.product_type,
        products.product_price,
        product_supply_costs.total_supply_cost,
        products.product_price - product_supply_costs.total_supply_cost as gross_profit,
        safe_divide(
            products.product_price - product_supply_costs.total_supply_cost,
            products.product_price
        ) as gross_margin_percentage,
        products.product_price * (1 + stores.tax_rate) as tax_adjusted_customer_price,
        1 as sold_unit_count

    from {{ ref('stg_items') }} as items
    inner join {{ ref('stg_orders') }} as orders
        on items.order_id = orders.order_id
    inner join {{ ref('stg_products') }} as products
        on items.sku = products.sku
    inner join {{ ref('stg_stores') }} as stores
        on orders.store_id = stores.store_id
    left join product_supply_costs
        on items.sku = product_supply_costs.sku

)

select * from sales
