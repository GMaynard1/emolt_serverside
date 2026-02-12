/*
* Title: view_all_hardware_addresses.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: To create a view called `all_hardware_addresses` that contains the 
*   hardware address types and values for all equipment listed in the view
*   `most_recent_gear_install`
*/
CREATE OR REPLACE VIEW zz_all_hardware_addresses AS
SELECT 
  HARDWARE_ADDRESSES.ADDRESS_TYPE,
  HARDWARE_ADDRESSES.HARDWARE_ADDRESS,
  zz_most_recent_gear_install.*
FROM 
  HARDWARE_ADDRESSES
  INNER JOIN 
  zz_most_recent_gear_install
  ON HARDWARE_ADDRESSES.INVENTORY_ID = zz_most_recent_gear_install.END_INVENTORY_ID