CREATE TABLE `TOW_SENSORS`(
  `TOW_SENSOR_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `TOW_ID` integer NOT NULL COMMENT 'Links this table to the TOWS table',
  `INVENTORY_ID` integer NOT NULL COMMENT 'Links this table to the EQUIPMENT_INVENTORY table',
  `UPLOAD_TIME` datetime NULL COMMENT 'Timestamp (UTC) for the most recent upload from this tow',
  `UPLOAD_SOURCE` set('SAT','WIFI','CELL','MANUAL') NOT NULL COMMENT 'Describes whether the data were uploaded directly by satellite as summary information or loaded in their raw format via another transmission method (requiring summary stats be calculated after the fact)',
  `DATAFILE` varchar(255) NULL COMMENT 'Raw data filename (if applicable, NULL for satellite transmission)',
  PRIMARY KEY (`TOW_SENSOR_ID`),
  
  CONSTRAINT fkTOW_ID
    FOREIGN KEY (`TOW_ID`)
    REFERENCES TOWS(TOW_ID),
  CONSTRAINT fkEquipID
    FOREIGN KEY (`INVENTORY_ID`)
    REFERENCES EQUIPMENT_INVENTORY(INVENTORY_ID)
)COMMENT='This table describes which instruments were used on which tows';