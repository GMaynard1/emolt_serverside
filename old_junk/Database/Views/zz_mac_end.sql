CREATE OR REPLACE VIEW zz_mac_end AS 
SELECT
zz_equipment_end.END_SERIAL AS END_SERIAL,
zz_equipment_end.END_MAKE AS END_MAKE,
zz_equipment_end.END_MODEL AS END_MODEL,
HARDWARE_ADDRESSES.HARDWARE_ADDRESS AS MAC,
VESSEL_VISIT_LOG.VESSEL_ID AS VESSEL_ID,
VESSEL_VISIT_LOG.VISIT_DATE AS VISIT_DATE 
FROM
  (
    (
      zz_equipment_end 
      LEFT JOIN 
      HARDWARE_ADDRESSES 
      ON
        (
          (
            zz_equipment_end.END_ID = HARDWARE_ADDRESSES.INVENTORY_ID
          )
        )
      ) 
      LEFT JOIN 
      VESSEL_VISIT_LOG 
      ON
        (
          (
            zz_equipment_end.VISIT_ID = VESSEL_VISIT_LOG.VISIT_ID
          )
        )
      ) 
      WHERE 
      (
        zz_equipment_end.END_TYPE = 'LOGGER'
      )