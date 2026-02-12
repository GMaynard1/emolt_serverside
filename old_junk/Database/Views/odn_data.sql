/*
* Title: odn_data_view.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a view of haul-averaged temperature and depth data with vessel, time, and location information
*/
CREATE OR REPLACE VIEW odn_data AS
SELECT
  zz_odn_temp.TOW_ID,
  zz_odn_temp.VESSEL_ID,
  zz_odn_temp.MEAN_TIME,
  zz_odn_temp.MEAN_LATITUDE,
  zz_odn_temp.MEAN_LONGITUDE,
  zz_odn_temp.MEAN_TEMPERATURE,
  zz_odn_depth.MEAN_DEPTH
FROM
  zz_odn_temp
  INNER JOIN
  zz_odn_depth ON zz_odn_temp.TOW_ID = zz_odn_depth.TOW_ID
;