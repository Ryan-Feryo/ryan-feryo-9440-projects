-- creating fact_restaurant_violation
WITH DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

-- All dimensions as CTEs for reference
dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),

dim_geography AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

dim_restaurant AS (
    SELECT * FROM {{ ref('dim_restaurant') }}
),

dim_violation AS (
    SELECT * FROM {{ ref('dim_violation') }}
),

dim_inspection AS (
    SELECT * FROM {{ ref('dim_inspection') }}
),

-- creating CTE for fact table
fact_restaurant_violation AS (

    SELECT
        -- surrogate_key
        {{ dbt_utils.generate_surrogate_key(['r.camis', 'r.inspection_date', 'r.inspection_type', 'r.violation_code']) }} AS violation_fact_key,
        -- Degenerate dimension
        i.inspection_key AS inspection_key,


        rr.restaurant_key AS restaurant_key,
        d.date_key AS inspection_date_key,
        g.geography_key AS geography_key,
        v.violation_key AS violation_key
        
    FROM stg_DOHMH_RIR r

    -- Left joins because you want all the rows from staging in the fact with key information from dimensions
    LEFT JOIN dim_date d
        ON d.full_date = CAST(r.inspection_date AS DATE)

    -- IS NOT DISTINCT FROM so a NULL zip / council_district matches the dim row
    LEFT JOIN dim_geography g
        ON  g.borough = r.borough
        AND g.zip_code IS NOT DISTINCT FROM r.zip_code
    
    LEFT JOIN dim_inspection i
        ON  i.inspection_id = r.inspection_id
        AND i.inspection_type IS NOT DISTINCT FROM r.inspection_type

    LEFT JOIN dim_restaurant rr
        ON rr.camis = r.camis
    
    LEFT JOIN dim_violation v
        ON  v.violation_code = r.violation_code
        AND v.violation_description IS NOT DISTINCT FROM r.violation_description
        AND v.critical_category IS NOT DISTINCT FROM r.critical_flag
)

SELECT * FROM fact_restaurant_violation