/*
* Title: emolt_dat_view.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Mimics the emolt.dat file using data ingested through the API
*/
CREATE OR REPLACE VIEW emolt_dat AS
SELECT
  vessel_sat.EMOLT_NUM,
  vessel_sat.HARDWARE_ADDRESS AS IMEI,
  zz_odn_temp.MEAN_TIME,
  zz_odn_temp.MEAN_LONGITUDE,
  zz_odn_temp.MEAN_LATITUDE,
  zz_odn_depth.MEAN_DEPTH,
  zz_odn_depth.RANGE_DEPTH,
  zz_odn_depth.SOAK_TIME,
  zz_odn_temp.MEAN_TEMPERATURE,
  zz_odn_temp.STD_TEMPERATURE
  
FROM
  zz_odn_temp
  INNER JOIN
  zz_odn_depth ON zz_odn_temp.TOW_ID = zz_odn_depth.TOW_ID
  INNER JOIN
  vessel_sat ON zz_odn_temp.VESSEL_ID = vessel_sat.VESSEL_ID
;