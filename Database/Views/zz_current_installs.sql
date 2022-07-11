/*
* Title: view_current_installs.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: View all equipment that is currently installed (was installed and does 
*           not have a recorded removal)
*/
SELECT 
  zz_all_installs.INSTALL_DATE,
  zz_all_installs.END_INVENTORY_ID,
  zz_all_installs.VESSEL_ID,
  zz_all_replacements.REPLACEMENT_DATE,
  zz_all_replacements.VESSEL_EQUIPMENT,
  zz_all_replacements.START_INVENTORY_ID
FROM 
  zz_all_replacements
  RIGHT OUTER JOIN
  zz_all_installs
  ON zz_all_replacements.VESSEL_EQUIPMENT = zz_all_installs.VESSEL_EQUIPMENT
WHERE 
  zz_all_replacements.REPLACEMENT_DATE IS NULL
  OR
  zz_all_replacements.REPLACEMENT_DATE < zz_all_installs.INSTALL_DATE
;