with source as (

    select * from {{ source('jaffle_shop', 'raw_products') }}

),

renamed as (

    select
        sku,
        name as product_name,
        type as product_type,
        description as product_description,
        {{ cents_to_dollars('price') }} as product_price
    from source

)

select * from renamed