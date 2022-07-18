/*
* Title: zz_code_temp_part1
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Building towards improved version of code_temp.dat, only includes active loggers
*/
CREATE OR REPLACE VIEW zz_code_temp_part1 AS
SELECT
  vessel_mac.VESSEL_NAME,
  vessel_mac.EMOLT_NUM,
  vessel_mac.HARDWARE_ADDRESS AS MAC_ADDRESS,
  vessel_sat.HARDWARE_ADDRESS AS IMEI
FROM 
  vessel_mac
INNER JOIN
  vessel_sat
  ON vessel_mac.EMOLT_NUM = vessel_sat.EMOLT_NUM
WHERE vessel_mac.EQUIPMENT_TYPE = 'LOGGER'
;