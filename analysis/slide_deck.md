# Jaffle Shop Product Mix Recommendations

---

## 1. Problem

Jaffle Shop wants to improve store-level sales by promoting product combinations that customers are already likely to buy.

The business question:

> Which product pairings should Philadelphia promote, and which supplies should the store increase to support those recommendations?

---

## 2. Why This Matters

The raw data includes orders, items, products, stores, and supplies.

Using dbt, we can connect:

- What customers bought
- What they bought next
- Which products are profitable
- Which supplies support those products

This turns transaction data into an actionable promotion and supply planning recommendation.

---

## 3. Analytics Approach

I built a dbt pipeline with three layers:

| Layer | Purpose |
| --- | --- |
| Staging | Clean and standardize raw seed tables |
| Intermediate | Join orders, items, products, stores, and supplies |
| Marts | Create business-facing recommendation outputs |

Key marts used:

- `fct_store_product_pair_recommendations`
- `fct_store_supply_distribution`

---

## 4. Recommendation Logic

Product pair recommendations combine:

- Product popularity: units sold
- Product profitability: gross profit and margin
- Funnel strength: how often customers buy the next product after the first product
- Store tax context: tax-adjusted customer price

Each product pair receives a weighted recommendation score, then is ranked within a promotion category.

---

## 5. Promotion Categories

The final recommendation mart produces the top 3 pairings for each category:

| Promotion category | Meaning |
| --- | --- |
| `food_bev_pairing` | Jaffle to beverage or beverage to jaffle |
| `bev_bev_pairing` | Beverage to beverage |
| `jaffle_jaffle_pairing` | Jaffle to jaffle |

Current data only includes observed sales for Philadelphia, so recommendations are Philadelphia-specific.

---

## 6. Top Food and Beverage Pairings

| Rank | Recommended pairing | Funnel transitions | Recommendation score |
| --- | --- | ---: | ---: |
| 1 | for richer or pourover -> flame impala | 9 | 0.5549 |
| 2 | for richer or pourover -> the krautback | 8 | 0.5348 |
| 3 | for richer or pourover -> doctor stew | 7 | 0.5165 |

Insight:

`for richer or pourover` is the strongest starting product for food and beverage cross-sell promotions.

---

## 7. Top Beverage Pairings

| Rank | Recommended pairing | Funnel transitions | Recommendation score |
| --- | --- | ---: | ---: |
| 1 | for richer or pourover -> for richer or pourover | 34 | 0.9109 |
| 2 | for richer or pourover -> tangaroo | 30 | 0.8249 |
| 3 | for richer or pourover -> vanilla ice | 31 | 0.8165 |

Insight:

Beverage follow-up behavior is much stronger than jaffle follow-up behavior in the current data.

---

## 8. Top Jaffle Pairings

| Rank | Recommended pairing | Funnel transitions | Recommendation score |
| --- | --- | ---: | ---: |
| 1 | flame impala -> the krautback | 5 | 0.2061 |
| 2 | the krautback -> flame impala | 6 | 0.1891 |
| 3 | doctor stew -> flame impala | 5 | 0.1659 |

Insight:

Jaffle-to-jaffle pairings are weaker than beverage-led pairings, but `flame impala` appears repeatedly in the top recommendations.

---

## 9. Supply Mix Implications

Recommended products depend on perishable beverage and jaffle ingredients.

Non-perishable operating supplies such as cups, lids, straws, utensils, and napkins are excluded from this recommendation because they are baseline store needs.

Top recommended-product perishable supplies by estimated usage:

| Supply | Estimated units used | Share of supply units | Supports |
| --- | ---: | ---: | --- |
| coffee | 328 | 23.0% | pourover, vanilla ice |
| bread | 192 | 13.5% | doctor stew, flame impala, the krautback |
| french vanilla syrup | 160 | 11.2% | vanilla ice |
| cheese | 155 | 10.9% | doctor stew, flame impala, the krautback |
| mango | 154 | 10.8% | tangaroo |

---

## 10. Recommendation

For Philadelphia, prioritize these promotion moves:

1. Lead with `for richer or pourover` as the anchor product.
2. Promote cross-sell pairings with `flame impala`, `the krautback`, and `doctor stew`.
3. Increase perishable beverage inputs, especially coffee, french vanilla syrup, mango, and tangerine.
4. Increase jaffle support ingredients for promoted food products, especially bread, cheese, and product-specific perishables.

---

## 11. Expected Impact

This recommendation should help Philadelphia:

- Promote products with stronger observed next-purchase behavior
- Favor products with stronger gross profit and margin
- Align supply planning with the products most likely to drive sales
- Reduce the risk of understocking supplies tied to recommended promotions

---

## 12. Caveats and Next Steps

Caveats:

- Current observed order history only covers Philadelphia.
- Perishable supply distribution is estimated from product sales and SKU supply requirements, not actual shipment data.
- Each item row is treated as one unit sold, matching the workshop README guidance.

Next steps:

- Add shipment or inventory data if available.
- Extend store-level recommendations once more stores have observed orders.
- Compare recommendation performance before and after promotion changes.
- Add dashboard visuals for product pairs and supply usage.
