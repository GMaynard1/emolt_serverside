/*
* Title: view_most_recent_gear_install.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a view called `most_recent_gear_install` which displays the 
*   date of the most recent installation on board a vessel for each piece of 
*   gear that has installation records. For example, if Logger 123 was installed
*   on Vessel A on 2022-01-01 then removed from Vessel A and installed on Vessel
*   B on 2022-02-02, the view would show max_date = 2022-02-02 for Logger 123. 
*/
CREATE OR REPLACE VIEW zz_most_recent_gear_install AS
SELECT 
  END_INVENTORY_ID,
  max(VISIT_DATE) AS max_date
FROM zz_visit_changes
WHERE END_INVENTORY_ID IS NOT NULL 
GROUP BY END_INVENTORY_ID