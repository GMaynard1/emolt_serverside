CREATE OR REPLACE VIEW zz_equipment_end AS 
SELECT
EQUIPMENT_CHANGE.VISIT_ID AS VISIT_ID,
EQUIPMENT_CHANGE.END_INVENTORY_ID AS END_ID,
END.SERIAL_NUMBER AS END_SERIAL,
END.EQUIPMENT_TYPE AS END_TYPE,
END.MAKE AS END_MAKE,
END.MODEL AS END_MODEL
FROM
  (
  EQUIPMENT_CHANGE 
  LEFT JOIN 
  EQUIPMENT_INVENTORY 
  END 
  ON
    (
      (
      END.INVENTORY_ID = EQUIPMENT_CHANGE.END_INVENTORY_ID
      )
    )
  )