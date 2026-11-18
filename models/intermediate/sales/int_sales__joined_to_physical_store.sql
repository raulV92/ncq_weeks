with sales as (
    select * from {{ ref('stg_tlog__sales') }}
),
store_map as (
    select * from {{ ref('stg_reference__publicos_privados') }}
),
-- Turn each 1:1 pair into two lookup rows, one per code as it appears in tlog.
-- This allows a single equi-join on (store_id, code_type) instead of an OR join.
store_lookup as (
    select
        public_store_id  as CDM_STORE_ID,
        'public'         as code_type,
        public_store_id,
        private_store_id
    from store_map

    union all

    select
        private_store_id as CDM_STORE_ID,
        'private'        as code_type,
        public_store_id,
        private_store_id
    from store_map
),
joined as (
    select
        sales.week_number,
        sales.code_type,
        sales.CDM_STORE_ID,
        sales.CDM_TRANSACTION_ID,
        sales.CDM_PRODUCT_ID,
        sales.CDM_SALES_VALUE,
        sales.CDM_SALES_UNITS,
        sales.input_filename,

        store_lookup.CDM_STORE_ID is not null as is_mapped,

        -- If mapped: use the mapping. If not: keep the code on its own side.
        coalesce(
            store_lookup.public_store_id,
            case when sales.code_type = 'public' then sales.CDM_STORE_ID end
        ) as public_store_id,

        coalesce(
            store_lookup.private_store_id,
            case when sales.code_type = 'private' then sales.CDM_STORE_ID end
        ) as private_store_id,

        -- Physical store key: public code when mapped, own code otherwise.
        coalesce(store_lookup.public_store_id, sales.CDM_STORE_ID) as store_key

    from sales
    left join store_lookup
        on  sales.CDM_STORE_ID  = store_lookup.CDM_STORE_ID
        and sales.code_type = store_lookup.code_type

)

select * from joined
