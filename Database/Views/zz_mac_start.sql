CREATE OR REPLACE VIEW zz_mac_start AS 
select 
zz_equipment_start.START_SERIAL AS START_SERIAL,
zz_equipment_start.START_MAKE AS START_MAKE,
zz_equipment_start.START_MODEL AS START_MODEL,
HARDWARE_ADDRESSES.HARDWARE_ADDRESS AS MAC,
VESSEL_VISIT_LOG.VESSEL_ID AS VESSEL_ID,
VESSEL_VISIT_LOG.VISIT_DATE AS VISIT_DATE 
from 
  (
    (
      zz_equipment_start 
      left join 
      HARDWARE_ADDRESSES 
      on
        (
          (
          zz_equipment_start.START_ID = HARDWARE_ADDRESSES.INVENTORY_ID
          )
        )
      ) 
      left join 
      VESSEL_VISIT_LOG 
      on
        (
          (
          zz_equipment_start.VISIT_ID = VESSEL_VISIT_LOG.VISIT_ID
          )
        )
      ) 
      where 
      (
        zz_equipment_start.START_TYPE = 'LOGGER'
      )