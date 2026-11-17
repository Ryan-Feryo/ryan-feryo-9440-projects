WITH NYC_311_FEC AS (
    SELECT * FROM {{ ref('stg_NYC_311_FEC') }}
),

DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

all_locations AS (

    SELECT DISTINCT
        borough,
        zip_code
    FROM NYC_311_FEC
    WHERE borough IS NOT NULL
       OR zip_code IS NOT NULL

    UNION DISTINCT

    SELECT DISTINCT
        borough,
        zip_code
    FROM DOHMH_NYC_RIR
    WHERE borough IS NOT NULL
       OR zip_code IS NOT NULL

),

dim_geography AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'borough', 'zip_code'
        ]) }} AS geography_key,

        borough,
        zip_code

    FROM all_locations

),

-- Null placeholder row to handle NULL values.

null_placeholder AS (

    SELECT
        '-1' AS geography_key,
        CAST(NULL AS STRING) AS borough,
        CAST(NULL AS STRING) AS zip_code

)

SELECT * FROM dim_geography
UNION ALL
SELECT * FROM null_placeholder
