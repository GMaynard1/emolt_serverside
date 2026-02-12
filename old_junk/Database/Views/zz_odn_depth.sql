/*
* Title: odn_depth_view.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a view of haul-averaged depth data with vessel, time, and location information
*/
CREATE OR REPLACE VIEW zz_odn_depth AS
SELECT
  TOWS.TOW_ID,
  TOWS.VESSEL_ID,
  TOWS.MEAN_TIME,
  TOWS.MEAN_LATITUDE,
  TOWS.MEAN_LONGITUDE,
  TOWS.SOAK_TIME,
  TOWS_SUMMARY.TS_RANGE_VALUE AS RANGE_DEPTH,
  TOWS_SUMMARY.TS_MEAN_VALUE AS MEAN_DEPTH
FROM
  TOWS
  INNER JOIN
  TOWS_SUMMARY ON TOWS.TOW_ID = TOWS_SUMMARY.TOW_ID
WHERE TOWS_SUMMARY.TS_PARAMETER="DEPTH"
;