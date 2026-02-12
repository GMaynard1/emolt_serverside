/*
* Title: view_vessel_visits.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a view called `vessel_visits` that contains the vessel name
*   associated with each equipment change and visit
*/ 
CREATE OR REPLACE VIEW zz_vessel_visits AS
SELECT
  VESSEL_VISIT_LOG.VESSEL_ID,
  VESSEL_VISIT_LOG.VISIT_ID,
  VESSEL_VISIT_LOG.VISIT_DATE,
  VESSELS.VESSEL_NAME,
  VESSELS.EMOLT_NUM,
  VESSELS.PRIMARY_GEAR,
  VESSELS.PORT AS HOMEPORT,
  EQUIPMENT_CHANGE.END_INVENTORY_ID
  FROM
    VESSELS
    INNER JOIN
      VESSEL_VISIT_LOG
      INNER JOIN
      EQUIPMENT_CHANGE
      ON VESSEL_VISIT_LOG.VISIT_ID = EQUIPMENT_CHANGE.VISIT_ID
    ON VESSELS.VESSEL_ID = VESSEL_VISIT_LOG.VESSEL_ID
    ;