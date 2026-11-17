--creating fact_311_complaint
WITH NYC_311_FEC AS (
    SELECT * FROM {{ ref('stg_NYC_311_FEC') }}
),

-- All the dimensions in their own CTEs
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
        -- suurogate key
        {{ dbt_utils.generate_surrogate_key(['f.unique_key']) }} AS complaint_key,
        -- Degenerate dimension (business identifier)
        f.unique_key,

        d.date_key AS created_date_key,
        g.geography_key AS geography_key,
        p.problem_detail_key AS problem_detail_key
        

    FROM stg_NYC_311_FEC f

    -- Left joins because you want all the rows from staging in the fact, with key information from dimensions
    LEFT JOIN dim_date d
        ON d.full_date = CAST(f.created_date AS DATE)

    LEFT JOIN dim_geography g
        ON  g.borough = f.borough
        AND g.zip_code IS NOT DISTINCT FROM f.zip_code
    
    LEFT JOIN dim_problem_detail p
        ON p.problem_type = f.descriptor
       AND p.problem_detail IS NOT DISTINCT FROM f.descriptor_2
)

SELECT * FROM fact_311_complaint