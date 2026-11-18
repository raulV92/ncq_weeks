with sales as (

    select * from {{ ref('int_sales__joined_to_physical_store') }}

),

aggregated as (

    select
        store_key,
        public_store_id,
        private_store_id,
        is_mapped,
        week_number,
        CDM_PRODUCT_ID,

        -- public side
        count(case when code_type = 'public' then 1 end)                                    as public_line_count,
        count(distinct case when code_type = 'public' then CDM_TRANSACTION_ID end)          as public_ticket_count,
        sum(case when code_type = 'public' then cast(CDM_SALES_VALUE as decimal(18, 4)) end) as public_sales_value,
        sum(case when code_type = 'public' then cast(CDM_SALES_UNITS as decimal(18, 4)) end) as public_units_sold,

        -- private side
        count(case when code_type = 'private' then 1 end)                                   as private_line_count,
        count(distinct case when code_type = 'private' then CDM_TRANSACTION_ID end)         as private_ticket_count,
        sum(case when code_type = 'private' then cast(CDM_SALES_VALUE as decimal(18, 4)) end) as private_sales_value,
        sum(case when code_type = 'private' then cast(CDM_SALES_UNITS as decimal(18, 4)) end) as private_units_sold

    from sales
    group by all

)

select * from aggregated
