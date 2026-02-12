CREATE TABLE `EQUIPMENT_INVENTORY` (
  `INVENTORY_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `SERIAL_NUMBER` varchar(50) NOT NULL COMMENT 'The serial number of the hardware',
  `EQUIPMENT_TYPE` set('LOGGER','DECK_BOX','COMMS_UNIT') NOT NULL COMMENT 'The broad category of equipment this item falls into',
  `MAKE` varchar(50) NOT NULL COMMENT 'Equipment manufacturer',
  `MODEL` varchar(50) NOT NULL COMMENT 'Model number or other identifier from manufacturer',
  `SOFTWARE_VERSION` varchar(50) COMMENT 'Software version if applicable, else NULL',
  `FIRMWARE_VERSION` varchar(50) COMMENT 'Firmware version if applicable, else NULL',
  `CURRENT_LOCATION` set('HOME','LAB','VESSEL','MANUFACTURER','LOST','DECOMMISSIONED') NOT NULL COMMENT 'Where the equipment is currently located',
  `CUSTODIAN` integer COMMENT 'Contact of person who has possession of the equipment',
  `FUNDING_SOURCE` integer COMMENT 'How the initial purchase of the equipment was funded. This may not be known for older equipment, but should be tracked moving forward.',
  `PURCHASE_DATE` datetime COMMENT 'When the equipment was purchased. This may not be known for older equipment, but should be tracked moving forward.',
  `PURCHASE_PRICE_USD` integer COMMENT 'The initial cost of the device in US Dollars. This may not be known for older equipment, but should be tracked moving forward.',
  
  PRIMARY KEY (`INVENTORY_ID`),
  
  CONSTRAINT fk_FundingSource
    FOREIGN KEY (`FUNDING_SOURCE`) 
      REFERENCES FUNDING(FUNDING_ID),
  CONSTRAINT fk_Custodian 
    FOREIGN KEY (`CUSTODIAN`) 
      REFERENCES CONTACTS(CONTACT_ID)
) COMMENT='This table stores information regarding the current disposition of equipment owned by the eMOLT program';