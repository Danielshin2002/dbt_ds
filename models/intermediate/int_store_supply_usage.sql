with sales as (

    select * from {{ ref('int_sales_enriched') }}

),

supplies as (

    select * from {{ ref('stg_supplies') }}

),

supply_usage as (

    select
        sales.store_id,
        sales.store_name,
        sales.order_id,
        sales.item_id,
        sales.sku,
        sales.product_name,
        sales.product_type,
        supplies.supply_id,
        supplies.supply_name,
        supplies.is_perishable,
        supplies.supply_cost,
        1 as estimated_supply_unit_count

    from sales
    inner join supplies
        on sales.sku = supplies.sku

)

select * from supply_usage
