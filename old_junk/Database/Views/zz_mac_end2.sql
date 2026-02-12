CREATE OR REPLACE VIEW zz_mac_end2 AS
SELECT
zz_mac_end.END_SERIAL AS SERIAL,
zz_mac_end.END_MAKE AS MAKE,
zz_mac_end.END_MODEL AS MODEL,
zz_mac_end.MAC AS MAC,
zz_mac_end.VISIT_DATE AS VISIT_DATE,
VESSELS.VESSEL_NAME AS VESSEL_NAME,
GEAR_CODES.FMCODE AS GEAR_TYPE
FROM 
  (
  zz_mac_end 
  LEFT JOIN 
  VESSELS 
  ON
    (
      (
        zz_mac_end.VESSEL_ID = VESSELS.VESSEL_ID
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