CREATE TABLE `TOWS_RAW`(
  `TOWS_RAW_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `SEGMENT_ID` integer NULL COMMENT 'Links to a record in the SEGMENTS table if one is available',
  `TOW_ID` integer NOT NULL COMMENT 'Links to a record in the TOWS table',
  `TIMESTAMP` datetime NOT NULL COMMENT 'When the data point was collected',
  `LATITUDE` decimal(10,5) NOT NULL COMMENT 'Latitude at which the data point was collected',
  `LONGITUDE` decimal(10,5) NOT NULL COMMENT 'Longitude at which the data point was collected',
  `DEPTH` decimal(10,3) NULL COMMENT 'Depth (m) at which the data point was collected',
  `TEMPERATURE` decimal(10,3) NULL COMMENT 'Temperature (Celsius)',
  `DISSOLVED_OXYGEN` decimal(10,5) NULL COMMENT 'Dissolved oxygen level',
  `DATA_FLAG_1` varchar(3) NULL COMMENT 'Placeholder',
  `DATA_FLAG_2` varchar(3) NULL COMMENT 'Placeholder',
  
  PRIMARY KEY (`TOWS_RAW_ID`),
  
  CONSTRAINT fk_towId2
    FOREIGN KEY (`TOW_ID`)
    REFERENCES TOWS(TOW_ID),
  CONSTRAINT fk_segId2
    FOREIGN KEY (`SEGMENT_ID`)
    REFERENCES SEGMENTS(SEGMENT_ID)
)COMMENT='This table stores raw data collected from loggers';