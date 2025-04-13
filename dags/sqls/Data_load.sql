CREATE OR REPLACE PROCEDURE `project-beta-000002.BETA.Data_load`()
begin

insert into project-beta-000002.BETA.Final_Table

SELECT 
 date(pickup_datetime) as report_date,
 count(*) as total_trips,
 sum(passenger_count) as total_passengers,
 round(sum(total_amount),3) as total_fare,
 round(avg(trip_distance),3) as average_trip_distance,
 round(avg(trip_duration_minutes),3) as average_trip_duration,
 avg(average_speed_mph) as average_speed,
 max(trip_distance) as  max_trip_distance,
 min(trip_distance) as min_trip_distance, 
 event_timestamp 
 FROM `project-beta-000002.BETA_STG.Staging_Table` 
 where event_timestamp not in (select event_timestamp from project-beta-000002.BETA.stage_audit)
 group by vendor_id,payment_type,date(pickup_datetime),event_timestamp;


 insert into project-beta-000002.BETA.stage_audit  
 
select 
 count(*) as count_data,
 concat("project-beta-000002.BETA_STG.Staging_Table_",current_timestamp()) as table_name,
 event_timestamp FROM `project-beta-000002.BETA_STG.Staging_Table` 
 where event_timestamp not in (select event_timestamp from project-beta-000002.BETA.stage_audit) group by 
  event_timestamp;
  

end;