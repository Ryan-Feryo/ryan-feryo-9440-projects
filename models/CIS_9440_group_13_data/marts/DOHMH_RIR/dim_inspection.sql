-- Complaint type dimension for DOT 311 service requests.
-- Grain: one row per distinct (complaint_type, descriptor) combination.

WITH DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

distinct_inspection AS (

    SELECT DISTINCT
        CAST(inspection_id AS STRING) AS inspection_id
        CAST(inspection_type AS STRING) AS inspection_type
        CAST(inspection_date AS STRING) AS inspection_date
        CAST(score AS STRING) AS score
        CAST(grade AS STRING) AS grade
        CAST(grade_date AS STRING) AS grade_date


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
        grade_date


        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

    FROM distinct_inspection

),


dim_inspection AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'inspection_id', 'inspection_type', 'inspection_date', 'score', 'grade', 'grade_date'
        ]) }} AS inspection_key,

        inspection_id,
        inspection_type,
        inspection_date,
        score,
        grade,
        grade_date

    FROM enriched

)

SELECT * FROM dim_inspection
