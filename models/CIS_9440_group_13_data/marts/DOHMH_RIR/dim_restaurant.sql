--creating dim_restaurant table
-- Grain: one row per restaurant

WITH DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
), 

distinct_restaurant AS (

    SELECT DISTINCT
        camis,
        dba,
        cuisine_description,
        building,
        street

    FROM stg_DOHMH_RIR
    WHERE camis IS NOT NULL AND inspection_date IS NOT NULL

),

enriched AS (

    SELECT
        camis,
        dba,
        cuisine_description,
        building,
        street


        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

    FROM distinct_restaurant

),

dim_restaurant AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'camis', 'dba', 'cuisine_description', 'building', 'street'
        ]) }} AS restaurant_key,

        camis,
        dba,
        cuisine_description,
        building,
        street

    FROM enriched

)

SELECT * FROM dim_restaurant
