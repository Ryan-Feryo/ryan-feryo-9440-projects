WITH source AS (
   SELECT camis,
            dba,
            building,
            street,
            boro,
            zipcode,
            cuisine_description,
            inspection_date,
            action,
            violation_code,
            violation_description,
            critical_flag,
            score,
            grade,
            inspection_type
     FROM {{ source('DOHMH_NYC_RIR', 'DOHMH_NYC_Restaurant_Inspection_Results') }}
),


    cleaned AS (
        
    SELECT


       CAST(camis AS STRING) AS camis,
       CONCAT(CAST(camis AS STRING), '-', FORMAT_DATE('%Y-%m-%d',  DATE(CAST(inspection_date AS TIMESTAMP)))) as inspection_id,


       DATE(CAST(inspection_date AS TIMESTAMP)) AS inspection_date,
       

       CAST(dba AS STRING) AS dba,
       CAST(building AS STRING) AS building,
       CAST(street AS STRING) AS street,
       CAST(cuisine_description AS STRING) AS cuisine_description,
       CAST(action AS STRING) AS action,
       CAST(violation_code AS STRING) AS violation_code,
       CAST(violation_description AS STRING) AS violation_description,
       CAST(critical_flag AS STRING) AS critical_flag,
       CAST(score AS STRING) AS score,
       CAST(grade AS STRING) AS grade,
       CAST(inspection_type AS STRING) AS inspection_type,


       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(zipcode AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(zipcode AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(zipcode AS STRING)) = 5 THEN CAST(zipcode AS STRING)
           WHEN LENGTH(CAST(zipcode AS STRING)) = 9 THEN CAST(zipcode AS STRING)
           WHEN LENGTH(CAST(zipcode AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(zipcode AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(zipcode AS STRING)
           ELSE NULL
       END AS zip_code,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(boro)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(boro)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(boro)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(boro)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(boro)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters
   WHERE camis IS NOT NULL
   AND inspection_date IS NOT NULL
   AND boro IS NOT NULL
   AND CAST(inspection_date AS TIMESTAMP) >= TIMESTAMP ('2020-01-01')

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY camis, inspection_date, violation_code ORDER BY inspection_date DESC) = 1
)

SELECT * FROM cleaned