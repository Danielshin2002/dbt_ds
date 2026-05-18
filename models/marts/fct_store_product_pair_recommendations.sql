with store_product_performance as (

    select * from {{ ref('fct_store_product_performance') }}

),

product_funnel as (

    select * from {{ ref('fct_product_funnel') }}

),

pair_candidates as (

    select
        previous_product_performance.store_id,
        previous_product_performance.store_name,
        previous_product_performance.tax_rate,
        product_funnel.previous_product_sku,
        product_funnel.previous_product_name,
        product_funnel.previous_product_type,
        product_funnel.next_product_sku,
        product_funnel.next_product_name,
        product_funnel.next_product_type,
        case
            when product_funnel.previous_product_type != product_funnel.next_product_type
                then 'food_bev_pairing'
            when product_funnel.previous_product_type = 'beverage'
                and product_funnel.next_product_type = 'beverage'
                then 'bev_bev_pairing'
            when product_funnel.previous_product_type = 'jaffle'
                and product_funnel.next_product_type = 'jaffle'
                then 'jaffle_jaffle_pairing'
        end as promotion_pair_type,
        product_funnel.transition_count,
        product_funnel.customer_count,
        product_funnel.avg_days_between_orders,
        product_funnel.pct_of_previous_product_next_purchases,
        previous_product_performance.units_sold as previous_product_units_sold,
        previous_product_performance.gross_profit as previous_product_gross_profit,
        previous_product_performance.gross_margin_percentage
            as previous_product_gross_margin_percentage,
        previous_product_performance.avg_tax_adjusted_customer_price
            as previous_product_avg_tax_adjusted_customer_price,
        next_product_performance.units_sold as next_product_units_sold,
        next_product_performance.gross_profit as next_product_gross_profit,
        next_product_performance.gross_margin_percentage
            as next_product_gross_margin_percentage,
        next_product_performance.avg_tax_adjusted_customer_price
            as next_product_avg_tax_adjusted_customer_price

    from store_product_performance as previous_product_performance
    inner join product_funnel
        on previous_product_performance.sku = product_funnel.previous_product_sku
    inner join store_product_performance as next_product_performance
        on previous_product_performance.store_id = next_product_performance.store_id
        and product_funnel.next_product_sku = next_product_performance.sku

    where (
        product_funnel.previous_product_type != product_funnel.next_product_type
        or (
            product_funnel.previous_product_type = 'beverage'
            and product_funnel.next_product_type = 'beverage'
        )
        or (
            product_funnel.previous_product_type = 'jaffle'
            and product_funnel.next_product_type = 'jaffle'
        )
    )

),

scored_pairs as (

    select
        *,
        safe_divide(
            pct_of_previous_product_next_purchases
                - min(pct_of_previous_product_next_purchases) over (partition by store_id),
            nullif(
                max(pct_of_previous_product_next_purchases) over (partition by store_id)
                    - min(pct_of_previous_product_next_purchases) over (partition by store_id),
                0
            )
        ) as normalized_pair_funnel_strength,
        safe_divide(
            previous_product_gross_profit
                - min(previous_product_gross_profit) over (partition by store_id),
            nullif(
                max(previous_product_gross_profit) over (partition by store_id)
                    - min(previous_product_gross_profit) over (partition by store_id),
                0
            )
        ) as normalized_previous_product_profit,
        safe_divide(
            previous_product_units_sold
                - min(previous_product_units_sold) over (partition by store_id),
            nullif(
                max(previous_product_units_sold) over (partition by store_id)
                    - min(previous_product_units_sold) over (partition by store_id),
                0
            )
        ) as normalized_previous_product_units_sold,
        safe_divide(
            next_product_gross_profit
                - min(next_product_gross_profit) over (partition by store_id),
            nullif(
                max(next_product_gross_profit) over (partition by store_id)
                    - min(next_product_gross_profit) over (partition by store_id),
                0
            )
        ) as normalized_next_product_profit,
        safe_divide(
            previous_product_avg_tax_adjusted_customer_price
                - min(previous_product_avg_tax_adjusted_customer_price)
                    over (partition by store_id),
            nullif(
                max(previous_product_avg_tax_adjusted_customer_price)
                    over (partition by store_id)
                    - min(previous_product_avg_tax_adjusted_customer_price)
                        over (partition by store_id),
                0
            )
        ) as normalized_tax_adjusted_price_penalty

    from pair_candidates

),

ranked_pairs as (

    select
        *,
        round(
            0.35 * coalesce(normalized_pair_funnel_strength, 0)
            + 0.30 * coalesce(normalized_previous_product_profit, 0)
            + 0.20 * coalesce(normalized_previous_product_units_sold, 0)
            + 0.15 * coalesce(normalized_next_product_profit, 0)
            - 0.05 * coalesce(normalized_tax_adjusted_price_penalty, 0),
            4
        ) as recommendation_score

    from scored_pairs

),

final as (

    select
        *,
        row_number() over (
            partition by store_id, promotion_pair_type
            order by recommendation_score desc, transition_count desc, previous_product_sku, next_product_sku
        ) as recommendation_rank

    from ranked_pairs

)

select * from final
where recommendation_rank <= 3
