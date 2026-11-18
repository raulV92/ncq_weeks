with unmapped as (
    select * from {{ ref('int_sales__item_store_week') }}
    where not is_mapped
),

store_week as (
    select
        store_key                                                         as store_id,
        case when public_store_id is not null then 'public' else 'private' end as code_type,
        week_number,

        count(*)                                                          as item_count,
        sum(public_line_count + private_line_count)                       as line_count,
        sum(coalesce(public_sales_value, 0) + coalesce(private_sales_value, 0)) as sales_value,
        sum(coalesce(public_units_sold, 0)  + coalesce(private_units_sold, 0))  as units_sold
    from unmapped
    group by all
)

select * from store_week
