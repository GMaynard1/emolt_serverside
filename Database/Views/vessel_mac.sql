/*
* Title: view_vessel_mac.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Displays the MAC address(es) of the devices assigned to each vessel
*/
CREATE OR REPLACE VIEW vessel_mac AS
SELECT
  zz_vessel_visits.VESSEL_NAME,
  zz_vessel_visits.EMOLT_NUM,
  zz_vessel_visits.VISIT_DATE,
  zz_vessel_visits.VESSEL_ID,
  zz_installed_gear_and_addresses.EQUIPMENT_TYPE,
  zz_installed_gear_and_addresses.MAKE,
  zz_installed_gear_and_addresses.MODEL,
  zz_installed_gear_and_addresses.HARDWARE_ADDRESS,
  zz_installed_gear_and_addresses.SERIAL_NUMBER
FROM
  zz_vessel_visits
  INNER JOIN
  zz_installed_gear_and_addresses
  ON zz_vessel_visits.VISIT_DATE = zz_installed_gear_and_addresses.max_date AND zz_vessel_visits.END_INVENTORY_ID = zz_installed_gear_and_addresses.END_INVENTORY_ID
WHERE zz_installed_gear_and_addresses.ADDRESS_TYPE LIKE '%MAC%'
;