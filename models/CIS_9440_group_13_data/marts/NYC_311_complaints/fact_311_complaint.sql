WITH 

NYC_311_FEC AS (
    SELECT * FROM {{ ref('stg_NYC_311_FEC') }}
),

fact_restaurant_violation AS (

    SELECT

       {{ dbt_utils.generate_surrogate_key(['unique_key']) }} AS complaint_key,

       
            unique_key,

        {{ dbt_utils.generate_surrogate_key([
            'CAST(created_date AS DATE)'
        ]) }} AS date_key,

        {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS geography_key,


        CASE
            WHEN descriptor IS NULL THEN '-1'
            ELSE {{ dbt_utils.generate_surrogate_key([
                'descriptor', 'descriptor_2'
            ]) }}
        END AS problem_detail_key,


        FROM NYC_311_FEC

)

SELECT * FROM fact_311_complaint