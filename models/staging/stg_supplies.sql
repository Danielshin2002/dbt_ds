with source as (

    select * from {{ source('jaffle_shop', 'raw_supplies') }}

),

renamed as (

    select
        id as supply_id,
        name as supply_name,
        cast(perishable as bool) as is_perishable,
        sku,
        {{ cents_to_dollars('cost') }} as supply_cost

    from source

)

select * from renamed