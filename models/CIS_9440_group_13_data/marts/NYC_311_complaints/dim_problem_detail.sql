-- Complaint type dimension for DOT 311 service requests.
-- Grain: one row per distinct (complaint_type, descriptor) combination.

WITH NYC_311_FEC AS (
    SELECT * FROM {{ ref('stg_NYC_311_FEC') }}
),

distinct_problem_details AS (

    SELECT DISTINCT
        CAST(descriptor AS STRING) AS problem_type
        CAST(descriptor_2 AS STRING) AS problem_detail
    FROM NYC_311_FEC
    WHERE problem_type IS NOT NULL

),

enriched AS (

    SELECT
        problem_type,
        problem_detail,

        -- Derived category, based on keywords appearing in descriptor
        -- Order matters due to CASE WHEN structure (worth considering)
        -- Match is case insensitive

    FROM distinct_problem_details

),

dim_problem_detail AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'problem_type', 'problem_detail'
        ]) }} AS problem_detail_key,

        problem_type,
        problem_detail

    FROM enriched

)

SELECT * FROM dim_problem_detail
