CREATE OR REPLACE VIEW zz_odn_temp_raw AS
SELECT
  TOWS_RAW.TOW_ID,
  TOWS_RAW.TIMESTAMP,
  TOWS_RAW.TR_VALUE AS TEMP
FROM 
  TOWS_RAW
INNER JOIN
  TOWS
ON
  TOWS.TOW_ID=TOWS_RAW.TOW_ID
WHERE
  TOWS_RAW.TR_PARAMETER = 'TEMP' AND TOWS.VESSEL_ID = 26
;