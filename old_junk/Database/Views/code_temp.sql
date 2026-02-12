/*
* Title: code_temp
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Improved version of code_temp.dat, only includes active loggers
*/
CREATE OR REPLACE VIEW code_temp AS
SELECT
  zz_code_temp_part1.*,
  GEAR_CODES.FMCODE
FROM 
  zz_code_temp_part1
INNER JOIN
  VESSELS
  INNER JOIN
    GEAR_CODES
    ON VESSELS.PRIMARY_GEAR = GEAR_CODES.GEAR_CODE
  ON zz_code_temp_part1.EMOLT_NUM = VESSELS.EMOLT_NUM
ORDER BY
zz_code_temp_part1.EMOLT_NUM
;