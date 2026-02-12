/*
* Title: view_all_installs
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: To create a view called `all_installs` that contains the information
*   for every piece of hardware installed on every vessel
*/
CREATE OR REPLACE VIEW zz_all_installs AS
SELECT
  VESSEL_VISIT_LOG.VISIT_DATE AS INSTALL_DATE,
  concat(VESSEL_VISIT_LOG.VESSEL_ID,'_',EQUIPMENT_CHANGE.END_INVENTORY_ID) AS VESSEL_EQUIPMENT,
  VESSEL_VISIT_LOG.VESSEL_ID,
  EQUIPMENT_CHANGE.END_INVENTORY_ID
FROM
  EQUIPMENT_CHANGE
  INNER JOIN
  VESSEL_VISIT_LOG
  ON EQUIPMENT_CHANGE.VISIT_ID = VESSEL_VISIT_LOG.VISIT_ID
WHERE
  EQUIPMENT_CHANGE.END_INVENTORY_ID IS NOT NULL;