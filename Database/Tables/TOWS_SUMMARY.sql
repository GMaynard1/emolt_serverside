CREATE TABLE `TOWS_SUMMARY`(
  `TOW_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `VESSEL_ID` integer NOT NULL COMMENT 'Ties tow or haul data to vessel table',
  `INVENTORY_ID` integer NOT NULL COMMENT 'Ties tow or haul data to a particular instrument',
  `UPLOAD_TIME` datetime NULL COMMENT 'Timestamp (UTC) for the most recent upload from this tow',
  `DATAFILE` varchar(255) COMMENT 'Raw data filename (if applicable, NULL for satellite transmission)',
  `MEAN_LATITUDE` decimal(10,5) NULL COMMENT 'Haul-averaged latitude',
  `MEAN_LONGITUDE` decimal(10,5) NULL COMMENT 'Haul-averaged longitude',
  `MEAN_DEPTH` integer NULL COMMENT 'Haul-averaged depth (m)',
  `RANGE_DEPTH` integer NULL COMMENT 'Absolute difference (m) between min and max depths of the haul',
  `SOAK_TIME` integer NULL COMMENT 'Tow or soak time (minutes)',
  `MEAN_TIME` dateimte NULL COMMENT 'The temporal midpoint of the tow or soak',
  `MEAN_TEMP` decimal(5,2) NULL COMMENT 'Haul-averaged bottom temperature (Celsius)',
  `STD_TEMP` decimal(5,2) NULL COMMENT 'Standard deviation of bottom temps during the haul',
  `MEAN_DO` decimal(5,2) NULL COMMENT 'Average dissolved oxygen (UNITS) recorded during the tow',
  `STD_DO` decimal(5,2) NULL COMMENT 'Standard deviation of dissolved oxygen recorded during the tow',
  `DATA_SOURCE` set('SAT','WIFI','CELL','MANUAL') NOT NULL COMMENT 'Describes whether the data were uploaded directly by satellite as summary information or loaded in their raw format via another transmission method (requiring summary stats be calculated after the fact)' 
  PRIMARY KEY (`TOW_ID`),
  
  CONSTRAINT fk_invId
    FOREIGN KEY (`INVENTORY_ID`) 
      REFERENCES EQUIPMENT_INVENTORY(INVENTORY_ID),
  CONSTRAINT fk_vesID
    FOREIGN KEY (`VESSEL_ID`)
      REFERENCES VESSELS(VESSEL_ID)
)COMMENT='This table stores metadata from individual tows or hauls of fishing gear. Tow and haul are used to mean the same thing, although in common parlance, "tows" are taken with mobile gear and "hauls" are made with fixed gear. Both gear types "soak" in the water.';