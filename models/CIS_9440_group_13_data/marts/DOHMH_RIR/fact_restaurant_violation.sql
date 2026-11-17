-- Make sure you have access to staging and its grain
WITH DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

-- All the dimensions in their own CTEs for easy reference
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

-- Build intiial CTE for fact table
fact_restaurant_violation AS (

    SELECT
        -- Fact's own surrogate key, from the grain (this is deduped in staging)
        {{ dbt_utils.generate_surrogate_key(['r.camis', 'r.inspection_date', 'r.inspection_type', 'r.violation_code']) }} AS violation_fact_key,
        -- Degenerate dimension (business identifier)
        i.inspection_key AS inspection_key,
        rr.restaurant_key AS restaurant_key,
        -- Staging guarantees created_date: a NULL key here is a bug
        d.date_key AS inspection_date_key,
        -- Always will have a location key
        g.geography_key AS geography_key,
        -- Always will have a complaint type for this fact table
        v.violation_key AS violation_key
        

    FROM stg_DOHMH_RIR r

    -- Left joins because you want all the rows from staging in the fact rep'd, with key information from dimensions
    -- JOIN ON the items that make up the surrogate key in the dimension
    LEFT JOIN dim_date d
        ON d.full_date = CAST(r.inspection_date AS DATE)

    -- IS NOT DISTINCT FROM so a NULL zip / council_district matches the dim row
    -- Could leave out the NULL exception and make these =s
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