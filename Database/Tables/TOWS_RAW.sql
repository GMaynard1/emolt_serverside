CREATE TABLE `TOWS_RAW`(
  `TOWS_RAW_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `TOW_ID` integer NOT NULL COMMENT 'Links to a record in the TOWS table',
  `TOW_SEGMENT_ID` integer NULL COMMENT 'Links to a record in the TOWS_SEGMENTS table',
  `TIMESTAMP` datetime NOT NULL COMMENT 'When the data point was collected',
  `LATITUDE` decimal(10,5) NOT NULL COMMENT 'Latitude at which the data point was collected',
  `LONGITUDE` decimal(10,5) NOT NULL COMMENT 'Longitude at which the data point was collected',
  `TR_VALUE` decimal(10,5) NOT NULL COMMENT 'Observed value of a parameter at a given time and location',
  `TR_PARAMETER` set('TEMP','DEPTH','DO','PH','SPEED','DIR','N_VELO','E_VELO','YAW','PITCH','ROLL','HEADING','TILT_FROM_VERT','TURBIDITY','CONDUCTIVITY','PAR') NOT NULL COMMENT "Parameters that can be measured",
  `TR_UOM` set('DEGREES CELSIUS','m','PERCENT','mg/L','pH','cm/s','BEARING DEGREES','FTU','uS','umol/s') NOT NULL COMMENT "Units of measure parameter values are recorded in",
  `DATA_FLAG_1` varchar(3) NULL COMMENT 'Placeholder',
  `DATA_FLAG_2` varchar(3) NULL COMMENT 'Placeholder',
  
  PRIMARY KEY (`TOWS_RAW_ID`),
  
  CONSTRAINT fk_segId2
    FOREIGN KEY (`TOW_SEGMENT_ID`)
    REFERENCES TOW_SEGMENTS(TOW_SEGMENT_ID)
  CONSTRAINT fk_towID2
    FOREIGN KEY (`TOW_ID`)
    REFERENCES TOWS(TOW_ID)
)COMMENT='This table stores raw data collected from loggers';