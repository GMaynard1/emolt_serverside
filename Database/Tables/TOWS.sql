CREATE TABLE `TOWS`(
  `TOW_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `VESSEL_ID` integer NOT NULL COMMENT 'Ties tow or haul data to vessel table',
  `UPLOAD_TIME` datetime NULL COMMENT 'Timestamp (UTC) for the most recent upload from this tow',
  `UPLOAD_SOURCE` set('SAT','WIFI','CELL','MANUAL') NOT NULL COMMENT 'Describes whether the data were uploaded directly by satellite as summary information or loaded in their raw format via another transmission method (requiring summary stats be calculated after the fact)',
  `DATAFILE` varchar(255) NULL COMMENT 'Raw data filename (if applicable, NULL for satellite transmission)',
  `MEAN_LATITUDE` decimal(10,5) NULL COMMENT 'Haul-averaged latitude',
  `MEAN_LONGITUDE` decimal(10,5) NULL COMMENT 'Haul-averaged longitude',
  `SOAK_TIME` integer NULL COMMENT 'Tow or soak time (minutes)',
  `MEAN_TIME` datetime NULL COMMENT 'The temporal midpoint of the tow or soak',
  
  PRIMARY KEY (`TOW_ID`),
  
  CONSTRAINT fk_vesID
    FOREIGN KEY (`VESSEL_ID`)
      REFERENCES VESSELS(VESSEL_ID)
)COMMENT='This table stores metadata from individual tows or hauls of fishing gear. Tow and haul are used to mean the same thing, although in common parlance, "tows" are taken with mobile gear and "hauls" are made with fixed gear. Both gear types "soak" in the water.';