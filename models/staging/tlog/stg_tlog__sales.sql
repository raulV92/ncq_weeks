with source as (
  select * from {{ source('tlog', 'tlog') }}
),
renamed as (
  select
    CDM_STORE_ID,
    CDM_TRANSACTION_ID,
    CDM_PRODUCT_ID,

    CDM_SALES_VALUE,
    CDM_SALES_UNITS,

    input_filename,

    cast(
      regexp_extract(input_filename, 'SEMANA([0-9]{2})', 1)
      as int
    ) as week_number,

    case
      when contains(input_filename, 'CODIGOS_PUBLICOS')
        then 'public'
      else 'private'
    end as code_type
  from source
)

select * from renamed
