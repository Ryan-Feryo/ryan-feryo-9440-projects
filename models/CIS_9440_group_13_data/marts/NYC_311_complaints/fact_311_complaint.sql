-- Make sure you have access to staging and its grain
WITH NYC_311_FEC AS (
    SELECT * FROM {{ ref('stg_NYC_311_FEC') }}
),

-- All the dimensions in their own CTEs for easy reference
dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
),

dim_geography AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

dim_problem_detail AS (
    SELECT * FROM {{ ref('dim_problem_detail') }}
),

-- Build intiial CTE for fact table
fact_311_complaint  AS (

    SELECT
        -- Fact's own surrogate key, from the grain (this is deduped in staging)
        {{ dbt_utils.generate_surrogate_key(['f.unique_key']) }} AS complaint_key,
        -- Degenerate dimension (business identifier)
        f.unique_key,
        -- Staging guarantees created_date: a NULL key here is a bug
        d.date_key AS created_date_key,
        -- Always will have a location key
        g.geography_key AS geography_key,
        -- Always will have a complaint type for this fact table
        p.problem_detail_key AS problem_detail_key
        

    FROM stg_NYC_311_FEC f

    -- Left joins because you want all the rows from staging in the fact rep'd, with key information from dimensions
    -- JOIN ON the items that make up the surrogate key in the dimension
    LEFT JOIN dim_date d
        ON d.full_date = CAST(f.created_date AS DATE)

    -- IS NOT DISTINCT FROM so a NULL zip / council_district matches the dim row
    -- Could leave out the NULL exception and make these =s
    LEFT JOIN dim_geography g
        ON  g.borough = f.borough
        AND g.zip_code IS NOT DISTINCT FROM f.zip_code
    
    LEFT JOIN dim_problem_detail p
        ON p.problem_type = f.descriptor
       AND p.problem_detail IS NOT DISTINCT FROM f.descriptor_2
)

SELECT * FROM fact_311_complaint