-- Clean and standardize 311 DOT service request data
-- One row per service request

WITH source AS (
   SELECT * FROM {{ source('raw_dob', 'source_nyc_dob_job_apps') }}
), -- Easier to refer to the dbt reference to a long name table this way

cleaned AS (
   SELECT
       -- Get all columns from source, except ones we're transforming below
       -- To do cleaning on them or explicitly cast them as types just in case
       * EXCEPT (
            job_filing_number,
            filing_status,
            house_no,
            street_name,
            borough,
            work_on_floor,
            initial_cost,
            filing_date,
            owner_s_business_name,
            current_status_date,
            first_permit_date,
            approved_date,
            sprinkler_work_type,
            plumbing_work_type,
            standpipe,
            antenna,
            sign,
            curb_cut,
            fence,
            scaffold,
            shed,
            boiler_equipment_work_type_,
            earth_work_work_type_,
            foundation_work_type_,
            general_construction_work_type_,
            mechanical_systems_work_type_,
            place_of_assembly_work_type_,
            protection_mechanical_methods_work_type_,
            sidewalk_shed_work_type_,
            structural_work_type_,
            support_of_excavation_work_type_,
            temporary_place_of_assembly_work_type_,
            green_roof_work_type_,
            solar_work_type_,
            full_demolition_work_type_,
            suspended_scaffold_work_type_,
            job_description,
            job_type,
            latitude,
            longitude,
            building_type,
            postcode,
            zip,

            filing_representative_first_name,
            filing_representative_last_name,
            filing_representative_business_name,
            filing_representative_street_name,
            filing_representative_city,
            filing_representative_zip
            
       ),

        --Filing Representative
       CAST(filing_representative_first_name AS STRING) AS filing_representative_first_name,
       CAST(filing_representative_last_name AS STRING) AS filing_representative_last_name,
       CAST(filing_representative_business_name AS STRING) AS filing_representative_business_name,
       CAST(filing_representative_street_name AS STRING) AS filing_representative_street_name,
       CAST(filing_representative_city AS STRING) AS filing_representative_city,
       CAST(filing_representative_zip AS STRING) AS filing_representative_zip,


       -- Identifiers
       CAST(job_filing_number AS STRING) AS job_filing_number,

       -- Date/Time
       CAST(filing_date AS TIMESTAMP) AS filing_date,
       CAST(current_status_date AS TIMESTAMP) AS current_status_date,
       CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
       CAST(approved_date AS TIMESTAMP) AS approved_date,

       -- Building Location and Characteristics
       CAST(house_no AS STRING) AS house_no,
       CAST(street_name AS STRING) AS street_name,
       CAST(borough AS STRING) AS borough,
       CAST(latitude AS FLOAT64) AS latitude,
       CAST(longitude AS FLOAT64) AS longitude,
       CAST(building_type AS STRING) AS building_type,
    

       CAST(owner_s_business_name AS STRING) AS owner_s_business_name,

       -- Job filing details
       CAST(filing_status AS STRING) AS filing_status,



       -- Work Type
       CAST(work_on_floor AS STRING) AS work_on_floor,
       CAST(sprinkler_work_type AS STRING) AS sprinkler_work_type,
       CAST(plumbing_work_type AS STRING) AS plumbing_work_type,
       CAST(standpipe AS STRING) AS standpipe,
       CAST(antenna AS STRING) AS antenna,
       CAST(sign AS STRING) AS sign,
       CAST(curb_cut AS STRING) AS curb_cut,
       CAST(fence AS STRING) AS fence,
       CAST(scaffold AS STRING) AS scaffold,
       CAST(shed AS STRING) AS shed,

       CAST(initial_cost AS FLOAT64) AS initial_cost,
       
       CAST(job_description AS STRING) AS job_description,
       CAST(boiler_equipment_work_type_ AS STRING) AS boiler_equipment_work_type_,
       CAST(earth_work_work_type_ AS STRING) AS earth_work_work_type_,
       CAST(foundation_work_type_ AS STRING) AS foundation_work_type_,
       CAST(general_construction_work_type_ AS STRING) AS general_construction_work_type_,
       CAST(mechanical_systems_work_type_ AS STRING) AS mechanical_systems_work_type_,
       CAST(place_of_assembly_work_type_ AS STRING) AS place_of_assembly_work_type_,
       CAST(protection_mechanical_methods_work_type_ AS STRING) AS protection_mechanical_methods_work_type_,
       CAST(sidewalk_shed_work_type_ AS STRING) AS sidewalk_shed_work_type_,
       CAST(structural_work_type_ AS STRING) AS structural_work_type_,
       CAST(support_of_excavation_work_type_ AS STRING) AS support_of_excavation_work_type_,
       CAST(temporary_place_of_assembly_work_type_ AS STRING) AS temporary_place_of_assembly_work_type_,
       CAST(green_roof_work_type_ AS STRING) AS green_roof_work_type_,
       CAST(solar_work_type_ AS STRING) AS solar_work_type_,
       CAST(full_demolition_work_type_ AS STRING) AS full_demolition_work_type_,
       CAST(suspended_scaffold_work_type_ AS STRING) AS suspended_scaffold_work_type_,
       CAST(job_type AS STRING) AS job_type,



       -- Location - clean zip code, handling several common zip code data problems
       CASE
           WHEN UPPER(TRIM(CAST(postcode AS STRING))) IN ('N/A', 'NA') THEN NULL

           WHEN LENGTH(CAST(postcode AS STRING)) = 5 THEN CAST(postcode AS STRING)
           WHEN LENGTH(CAST(postcode AS STRING)) = 9 THEN CAST(postcode AS STRING)
           WHEN LENGTH(CAST(postcode AS STRING)) = 10
               AND REGEXP_CONTAINS(CAST(postcode AS STRING), r'^\d{5}-\d{4}')
           THEN CAST(postcode AS STRING)
           ELSE NULL
       END AS zip,


   FROM source

   -- Deduplicate
   QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned
-- All should be part of this table after running: stg_nyc_311_dot
