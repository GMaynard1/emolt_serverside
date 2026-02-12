/*
* Title: vessel_gear.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: displays whether a vessel primarily fishes fixed or mobile gear
*/
CREATE OR REPLACE VIEW vessel_gear AS 
SELECT
  vessel_mac.VESSEL_NAME,
  vessel_mac.EMOLT_NUM,
  vessel_mac.VESSEL_ID,
  vessel_mac.PRIMARY_GEAR,
  GEAR_CODES.COMMON AS COMMON_NAME,
  GEAR_CODES.FMCODE
FROM
  vessel_mac
INNER JOIN
  GEAR_CODES
ON vessel_mac.PRIMARY_GEAR = GEAR_CODES.GEAR_CODE
;