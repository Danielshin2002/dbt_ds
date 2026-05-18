with sales as (

    select * from {{ ref('int_sales_enriched') }}

),

product_performance as (

    select
        store_id,
        store_name,
        tax_rate,
        sku,
        product_name,
        product_type,
        count(*) as units_sold,
        sum(product_price) as revenue,
        sum(total_supply_cost) as total_supply_cost,
        sum(gross_profit) as gross_profit,
        safe_divide(sum(gross_profit), sum(product_price)) as gross_margin_percentage,
        avg(tax_adjusted_customer_price) as avg_tax_adjusted_customer_price

    from sales
    group by
        store_id,
        store_name,
        tax_rate,
        sku,
        product_name,
        product_type

),

final as (

    select
        store_id,
        store_name,
        tax_rate,
        sku,
        product_name,
        product_type,
        units_sold,
        revenue,
        total_supply_cost,
        gross_profit,
        gross_margin_percentage,
        avg_tax_adjusted_customer_price,
        rank() over (
            partition by store_id
            order by units_sold desc, gross_profit desc, sku
        ) as product_popularity_rank

    from product_performance

)

select * from final
