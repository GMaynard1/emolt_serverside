CREATE OR REPLACE VIEW zz_visit_changes AS
SELECT 
  VESSEL_VISIT_LOG.VESSEL_ID, 
  VESSEL_VISIT_LOG.VISIT_DATE,
  EQUIPMENT_CHANGE.END_INVENTORY_ID,
  HARDWARE_ADDRESSES.ADDRESS_TYPE,
  HARDWARE_ADDRESSES.HARDWARE_ADDRESS
FROM 
  VESSEL_VISIT_LOG
  INNER JOIN
    EQUIPMENT_CHANGE
      INNER JOIN
        HARDWARE_ADDRESSES
      ON EQUIPMENT_CHANGE.END_INVENTORY_ID = HARDWARE_ADDRESSES.INVENTORY_ID
  ON VESSEL_VISIT_LOG.VISIT_ID = EQUIPMENT_CHANGE.VISIT_ID
;