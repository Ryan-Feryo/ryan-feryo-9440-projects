 -- Quick test to verify source connection works
 {{ config(
    materialized='table',
    hours_to_expiration=1000
) }}
 SELECT
     unique_key,
     created_date,
     complaint_type,
     borough
 FROM {{ source('raw', 'source_service_requests_homework') }}
 LIMIT 10