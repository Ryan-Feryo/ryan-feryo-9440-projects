-- Complaint type dimension for DOT 311 service requests.
-- Grain: one row per distinct (complaint_type, descriptor) combination.

WITH DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

distinct_violation AS (

    SELECT DISTINCT
        CAST(violation_code AS STRING) AS violation_code
        CAST(violation_description AS STRING) AS violation_description
        CAST(critical_category AS STRING) AS critical_category


    FROM stg_DOHMH_RIR
    WHERE violation_code IS NOT NULL

),

enriched AS (

    SELECT
        violation_code,
        violation_description,
        critical_category


        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

    FROM distinct_violation

),


dim_violation AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'violation_code', 'violation_description', 'critical_category'
        ]) }} AS violation_key,

        violation_code,
        violation_description,
        critical_category

    FROM enriched

)

SELECT * FROM dim_violation
