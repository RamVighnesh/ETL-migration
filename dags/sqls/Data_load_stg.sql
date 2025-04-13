CREATE OR REPLACE PROCEDURE `project-beta-000002.BETA_STG.Data_load_stg`()
begin

DECLARE row_id int64;

set row_id = COALESCE((SELECT MAX(record_id) FROM BETA_STG.Staging_Table), 0);

INSERT INTO
  project-beta-000002.BETA_STG.Staging_Table
  ( 
    record_id,
    vendor_id,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    pickup_location,
    dropoff_location,
    payment_type,
    trip_duration_minutes,
    total_amount,
    tolls_amount,
    fare_amount,
    tip_amount,
    extra,
    mta_tax,
    event_timestamp
  )
SELECT
row_id + row_number() over() ,
  CASE
    WHEN vendorid ="1" THEN "Creative Mobile Technologies"
    ELSE "VeriFone Inc."
END
  AS vendor_id,
  cast(tpep_pickup_datetime as timestamp),
  cast(tpep_dropoff_datetime as timestamp),
  cast(cast(passenger_count as float64) as int64),
  cast(trip_distance as float64),
  b.zone,
  c.zone,
  CASE
    WHEN payment_type="0" THEN "Flex Fare trip"
    WHEN payment_type="1" THEN "Credit card"
    WHEN payment_type="2" THEN "Cash"
    WHEN payment_type="3" THEN "No charge"
    WHEN payment_type="4" THEN "Dispute"
    WHEN payment_type="5" THEN "Unknown"
    ELSE "voided trip" 
  END
    AS payment_type,
  TIMESTAMP_DIFF(cast(tpep_dropoff_datetime as timestamp),cast(tpep_pickup_datetime as timestamp), minute),
  cast(total_amount as float64),
  cast(tolls_amount as float64),
  cast(fare_amount as float64),
  cast(tip_amount as float64),
  cast(extra as float64),
  cast(mta_tax as float64),
  parse_timestamp('%F_%H-%M-%S', event_timestamp)
 
FROM project-beta-000002.BETA_LANDING.Landing_Table a
left join project-beta-000002.BETA.taxi_zone_locations b on b.Locationid = cast(a.pulocationid as int64)  
left join project-beta-000002.BETA.taxi_zone_locations c on c.locationid = cast(a.dolocationid as int64);
  
end;