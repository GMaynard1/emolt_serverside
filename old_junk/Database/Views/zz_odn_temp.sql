/*
* Title: odn_temperature_view.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a view of haul-averaged temperature data with vessel, time, and location information
*/
CREATE OR REPLACE VIEW zz_odn_temp AS
SELECT
  TOWS.TOW_ID,
  TOWS.VESSEL_ID,
  TOWS.MEAN_TIME,
  TOWS.MEAN_LATITUDE,
  TOWS.MEAN_LONGITUDE,
  TOWS.SOAK_TIME,
  TOWS_SUMMARY.TS_MEAN_VALUE AS MEAN_TEMPERATURE,
  TOWS_SUMMARY.TS_STD_VALUE AS STD_TEMPERATURE
FROM
  TOWS
  INNER JOIN
  TOWS_SUMMARY ON TOWS.TOW_ID = TOWS_SUMMARY.TOW_ID
WHERE TOWS_SUMMARY.TS_PARAMETER="TEMP"
;