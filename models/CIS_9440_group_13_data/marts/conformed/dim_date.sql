

-- Build initial CTEs for Jinja syntax to make refs to staging models easier
WITH NYC_311_FEC AS (
    SELECT * FROM {{ ref('stg_NYC_311_FEC') }}
),

DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

-- Then union dates from the staging data together, collecting all poss dates
all_dates AS (

    -- 311 service requests: date roles referenced by fact_311_service_request
    SELECT DISTINCT CAST(created_date AS DATE) AS full_date
    FROM NYC_311_FEC
    WHERE created_date IS NOT NULL

    UNION DISTINCT



    -- DOHMH_NYC_Restaurant_Inspection_Results: date roles referenced by DOHMH_NYC_Restaurant_Inspection_Results
    SELECT DISTINCT CAST(inspection_date AS DATE) AS full_date
    FROM DOHMH_NYC_RIR
    WHERE inspection_date IS NOT NULL



),

-- Date dimension with NYC fiscal year, Jul 1 - Jun 30, diff from federal
dim_date AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} AS date_key,

        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(QUARTER FROM full_date) AS quarter,
        EXTRACT(MONTH FROM full_date) AS month,
        FORMAT_DATE('%B', full_date) AS month_name,
        EXTRACT(DAY FROM full_date) AS day_of_month,
        EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week,
        FORMAT_DATE('%A', full_date) AS weekday_name,
        EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) AS is_weekend

    FROM all_dates

),

-- Null placeholder row: to handle NULL values.
-- Building fact tables should COALESCE a null source date to this key
-- Keeps all fact and date_dim joins INNER JOINs safely
-- Kimball convention to be explicit. (More to come on this)

null_placeholder AS (

    SELECT
        '-1' AS date_key,
        CAST(NULL AS DATE) AS full_date,
        CAST(NULL AS INT64) AS year,
        CAST(NULL AS INT64) AS quarter,
        CAST(NULL AS INT64) AS month,
        CAST(NULL AS STRING) AS month_name,
        CAST(NULL AS INT64) AS day_of_month,
        CAST(NULL AS INT64) AS day_of_week,
        CAST(NULL AS STRING) AS weekday_name,
        CAST(NULL AS BOOLEAN) AS is_weekend
 
) 
-- make sure BQ knows the col types


SELECT * FROM dim_date

UNION ALL

SELECT * FROM null_placeholder
