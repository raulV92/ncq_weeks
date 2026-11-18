with source as (
  select * from {{ source('reference', 'publicos_privados_ncq') }}
),
renamed as (
  SELECT 
    trim(publico) as public_store_id,
    trim(SUCURSAL) as private_store_id
  FROM source

)

select * from renamed
