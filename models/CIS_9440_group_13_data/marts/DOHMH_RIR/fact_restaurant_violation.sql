WITH 

DOHMH_NYC_RIR AS (
    SELECT * FROM {{ ref('stg_DOHMH_RIR') }}
),

fact_restaurant_violation AS (

    SELECT

            {{ dbt_utils.generate_surrogate_key([
            'inspection_id', 'inspection_type', 'inspection_date', 'score', 'grade'
        ]) }} AS inspection_key,


            {{ dbt_utils.generate_surrogate_key(['camis']) }} AS restaurant_key,


            {{ dbt_utils.generate_surrogate_key([
            'CAST(inspection_date AS DATE)'
        ]) }} AS date_key,


        {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS geography_key,


        CASE
            WHEN violation_code IS NULL THEN '-1'
            ELSE {{ dbt_utils.generate_surrogate_key([
                'violation_code', 'violation_description', 'critical_flag'
            ]) }}
        END AS violation_key,

        CASE WHEN violation_code IS NOT NULL THEN 1 ELSE 0 END AS violation_count

    FROM DOHMH_NYC_RIR
)

SELECT * FROM fact_restaurant_violation