/*
* Title: view_installed_gear_and_addresses.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a view called `installed_gear_and_addresses` that matches all
*   installed gear to equipment make, model, and type stored in the equipment
*   inventory table. 
*/
CREATE OR REPLACE VIEW zz_installed_gear_and_addresses AS
  SELECT 
    EQUIPMENT_INVENTORY.EQUIPMENT_TYPE,
    EQUIPMENT_INVENTORY.MAKE,
    EQUIPMENT_INVENTORY.MODEL,
    EQUIPMENT_INVENTORY.SERIAL_NUMBER,
    zz_all_hardware_addresses.*
  FROM 
    EQUIPMENT_INVENTORY
    INNER JOIN
    zz_all_hardware_addresses
    ON EQUIPMENT_INVENTORY.INVENTORY_ID = zz_all_hardware_addresses.END_INVENTORY_ID