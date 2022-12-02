CREATE OR REPLACE VIEW zz_mac_start2 AS
SELECT
zz_mac_start.START_SERIAL AS SERIAL,
zz_mac_start.START_MAKE AS MAKE,
zz_mac_start.START_MODEL AS MODEL,
zz_mac_start.MAC AS MAC,
zz_mac_start.VISIT_DATE AS VISIT_DATE,
VESSELS.VESSEL_NAME AS VESSEL_NAME,
GEAR_CODES.FMCODE AS GEAR_TYPE
FROM 
  (
  zz_mac_start 
  LEFT JOIN 
  VESSELS 
  ON
    (
      (
        zz_mac_start.VESSEL_ID = VESSELS.VESSEL_ID
      )
    )
  )
  LEFT JOIN
  GEAR_CODES
  ON
    (
      (
      VESSELS.PRIMARY_GEAR = GEAR_CODES.GEAR_CODE
      )
    )