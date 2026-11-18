with item_store_week as (
    select * from {{ ref('int_sales__item_store_week') }}
    where is_mapped
),

compared as (
    select
        store_key,
        public_store_id,
        private_store_id,
        week_number,
        CDM_PRODUCT_ID,

        public_line_count,
        private_line_count,

        public_sales_value,
        private_sales_value,
        coalesce(private_sales_value, 0) - coalesce(public_sales_value, 0) as sales_value_diff,

        public_units_sold,
        private_units_sold,
        coalesce(private_units_sold, 0) - coalesce(public_units_sold, 0)   as units_sold_diff,

        greatest(
            {{ var('item_tolerance_min_abs') }},
            {{ var('item_tolerance_pct') }} * abs(coalesce(private_sales_value, 0))
        ) as sales_value_tolerance

    from item_store_week
),

classified as (
    select
        *,
        case
            when private_line_count = 0                     then 'only_public'
            when public_line_count  = 0                     then 'only_private'
            when abs(sales_value_diff) <= sales_value_tolerance then 'match'
            else 'mismatch'
        end as comparison_status

    from compared
)

select * from classified
