with source as (

    select * from {{ source('jaffle_shop', 'raw_items') }}

),

renamed as (

    select
        id as item_id,
        order_id,
        sku

    from source

)

select * from renamed