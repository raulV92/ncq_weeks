with items as (
    select * from {{ ref('fct_item_store_week_comparison') }}
),

store_week as (
    select
        store_key,
        public_store_id,
        private_store_id,
        week_number,

        -- totals
        sum(public_line_count)    as public_line_count,
        sum(private_line_count)   as private_line_count,
        sum(public_sales_value)   as public_sales_value,
        sum(private_sales_value)  as private_sales_value,
        sum(sales_value_diff)     as sales_value_diff,
        sum(abs(sales_value_diff)) as sales_value_abs_diff,
        sum(public_units_sold)    as public_units_sold,
        sum(private_units_sold)   as private_units_sold,
        sum(units_sold_diff)      as units_sold_diff,

        -- item-level findings
        count(*)                                        as item_count,
        count_if(comparison_status = 'match')           as items_match,
        count_if(comparison_status = 'mismatch')        as items_mismatch,
        count_if(comparison_status = 'only_public')     as items_only_public,
        count_if(comparison_status = 'only_private')    as items_only_private,
        sum(case when comparison_status = 'only_public'  then public_sales_value  end) as only_public_sales_value,
        sum(case when comparison_status = 'only_private' then private_sales_value end) as only_private_sales_value

    from items
    group by all
),
with_ratios as (
    select
        *,
        abs(sales_value_diff)  / nullif(abs(private_sales_value), 0) as sales_value_diff_pct,
        sales_value_abs_diff   / nullif(abs(private_sales_value), 0) as sales_value_abs_diff_pct,
        (items_only_public + items_only_private) / item_count        as pct_items_one_side
    from store_week
),

classified as (
    select
        *,
        case
            when private_line_count = 0 then 'only_public'
            when public_line_count  = 0 then 'only_private'
            -- private total = 0 makes the % undefined: flag it so it doesn't slip through
            when sales_value_diff_pct is null
              or sales_value_diff_pct >= {{ var('store_week_diff_threshold_pct') }} then 'over_threshold'
            else 'within_threshold'
        end as store_week_status
    from with_ratios
)

select * from classified
