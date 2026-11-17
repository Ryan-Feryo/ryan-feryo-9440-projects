-- Complaint type dimension for DOT 311 service requests.
-- Grain: one row per distinct (complaint_type, descriptor) combination.

WITH DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

distinct_inspection AS (

    SELECT DISTINCT
        inspection_id,
        inspection_type,
        inspection_date,
        score,
        grade,
 
    FROM stg_DOHMH_RIR
    WHERE inspection_id IS NOT NULL AND inspection_date IS NOT NULL

),

enriched AS (

    SELECT
        inspection_id,
        inspection_type,
        inspection_date,
        score,
        grade,

        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

    FROM distinct_inspection

),

dim_inspection AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'inspection_id', 'inspection_type', 'inspection_date', 'score', 'grade'
        ]) }} AS inspection_key,

        inspection_id,
        inspection_type,
        inspection_date,
        score,
        grade,


    FROM enriched

)

SELECT * FROM dim_inspection
