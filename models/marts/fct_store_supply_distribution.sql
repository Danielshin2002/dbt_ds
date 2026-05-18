with supply_usage as (

    select * from {{ ref('int_store_supply_usage') }}

),

recommended_product_pairs as (

    select
        store_id,
        promotion_pair_type,
        previous_product_sku as sku,
        previous_product_name as product_name

    from {{ ref('fct_store_product_pair_recommendations') }}

    union distinct

    select
        store_id,
        promotion_pair_type,
        next_product_sku as sku,
        next_product_name as product_name

    from {{ ref('fct_store_product_pair_recommendations') }}

),

recommended_supplies as (

    select
        recommended_product_pairs.store_id,
        supplies.supply_id,
        count(distinct recommended_product_pairs.sku) as recommended_product_count,
        string_agg(
            distinct recommended_product_pairs.product_name,
            ', '
            order by recommended_product_pairs.product_name
        ) as recommended_products_using_supply,
        string_agg(
            distinct recommended_product_pairs.promotion_pair_type,
            ', '
            order by recommended_product_pairs.promotion_pair_type
        ) as recommended_promotion_pair_types

    from recommended_product_pairs
    inner join {{ ref('stg_supplies') }} as supplies
        on recommended_product_pairs.sku = supplies.sku
    where supplies.is_perishable
    group by
        recommended_product_pairs.store_id,
        supplies.supply_id

),

store_supply_distribution as (

    select
        supply_usage.store_id,
        supply_usage.store_name,
        supply_usage.supply_id,
        supply_usage.supply_name,
        supply_usage.is_perishable,
        sum(supply_usage.estimated_supply_unit_count) as estimated_supply_units_used,
        sum(supply_usage.supply_cost) as estimated_supply_cost,
        count(distinct supply_usage.sku) as current_product_count_using_supply,
        string_agg(
            distinct supply_usage.product_name,
            ', '
            order by supply_usage.product_name
        ) as current_products_using_supply

    from supply_usage
    where supply_usage.is_perishable
    group by
        supply_usage.store_id,
        supply_usage.store_name,
        supply_usage.supply_id,
        supply_usage.supply_name,
        supply_usage.is_perishable

),

final as (

    select
        store_supply_distribution.store_id,
        store_supply_distribution.store_name,
        store_supply_distribution.supply_id,
        store_supply_distribution.supply_name,
        store_supply_distribution.is_perishable,
        store_supply_distribution.estimated_supply_units_used,
        store_supply_distribution.estimated_supply_cost,
        safe_divide(
            store_supply_distribution.estimated_supply_units_used,
            sum(store_supply_distribution.estimated_supply_units_used)
                over (partition by store_supply_distribution.store_id)
        ) as pct_of_store_supply_units,
        safe_divide(
            store_supply_distribution.estimated_supply_cost,
            sum(store_supply_distribution.estimated_supply_cost)
                over (partition by store_supply_distribution.store_id)
        ) as pct_of_store_supply_cost,
        store_supply_distribution.current_product_count_using_supply,
        store_supply_distribution.current_products_using_supply,
        coalesce(recommended_supplies.recommended_product_count, 0)
            as recommended_product_count_using_supply,
        recommended_supplies.recommended_products_using_supply,
        recommended_supplies.recommended_promotion_pair_types,
        recommended_supplies.recommended_product_count is not null
            as is_used_by_recommended_products,
        rank() over (
            partition by store_supply_distribution.store_id
            order by
                store_supply_distribution.estimated_supply_units_used desc,
                store_supply_distribution.estimated_supply_cost desc,
                store_supply_distribution.supply_id
        ) as store_supply_usage_rank

    from store_supply_distribution
    left join recommended_supplies
        on store_supply_distribution.store_id = recommended_supplies.store_id
        and store_supply_distribution.supply_id = recommended_supplies.supply_id

)

select * from final
