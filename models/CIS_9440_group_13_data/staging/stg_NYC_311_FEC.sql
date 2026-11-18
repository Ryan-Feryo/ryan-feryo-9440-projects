-- creating staging table for NYC_311_complaints
WITH source AS (
   SELECT unique_key,
          created_date,
          descriptor,
          descriptor_2,
          borough,
          incident_zip
   FROM {{ source('NYC_311_FEC', 'NYC_311_Food_Establishment_Complaints') }}
), 
--creating CTE to load the data needed and cleaning data when necessary
        cleaned AS (
        
    SELECT

       CAST(unique_key AS STRING) AS unique_key,
       CAST(created_date AS TIMESTAMP) AS created_date,

       -- Request details
       CAST(descriptor AS STRING) AS descriptor,
       CAST(descriptor_2 AS STRING) AS descriptor_2,

       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) IN ('N/A', 'NA') THEN NULL
           WHEN UPPER(TRIM(CAST(incident_zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
           WHEN LENGTH(CAST(incident_zip AS STRING)) = 5 THEN CAST(incident_zip AS STRING)
           WHEN LENGTH(CAST(incident_zip AS STRING)) = 9 THEN CAST(incident_zip AS STRING)
           WHEN LENGTH(CAST(incident_zip AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(incident_zip AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(incident_zip AS STRING)
           ELSE NULL
       END AS zip_code,

       -- Location - standardized borough, just in case
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN or CITYWIDE'
       END AS borough,

       -- Metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at

   FROM source

   -- Filters making start date 2020-01-01 to present
   WHERE unique_key IS NOT NULL
   AND created_date IS NOT NULL
   AND incident_zip IS NOT NULL
   AND borough IS NOT NULL
   AND CAST(created_date AS TIMESTAMP) >= TIMESTAMP ('2020-01-01')

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY unique_key ORDER BY created_date DESC) = 1
)

SELECT * FROM cleaned