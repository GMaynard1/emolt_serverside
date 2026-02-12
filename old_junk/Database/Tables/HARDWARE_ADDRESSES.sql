CREATE TABLE `HARDWARE_ADDRESSES` (
  `HARDWARE_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `INVENTORY_ID` integer COMMENT 'Foreign key from EQUIPMENT_INVENTORY',
  `ADDRESS_TYPE` varchar(50) COMMENT 'Type of address (e.g., MAC, Satellite, Bluetooth)',
  `HARDWARE_ADDRESS` varchar(100) COMMENT 'The actual address',
  
  PRIMARY KEY (`HARDWARE_ID`),
  
  CONSTRAINT fk_InventoryID
    FOREIGN KEY (`INVENTORY_ID`) 
      REFERENCES EQUIPMENT_INVENTORY(INVENTORY_ID)
) COMMENT='This table stores information about hardware addressess assigned to particular sensors or other items in the equipment inventory. They are recorded separately because they can change if equipment is refurbished by the manufacturer';