CREATE TABLE `TOWS_ENV`(
  `TOWS_ENV_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `TOWS_POINTS_ID` integer NOT NULL COMMENT 'Links to a record in the TOWS_POINTS table',
  `TOW_SEGMENT_ID` integer NULL COMMENT 'Links to a record in the TOWS_SEGMENTS table',
  `TR_VALUE` decimal(10,5) NOT NULL COMMENT 'Observed value of a parameter at a given time and location',
  `TR_PARAMETER` set('TEMP','DEPTH','DO','PH','SPEED','DIR','N_VELO','E_VELO','YAW','PITCH','ROLL','HEADING','TILT_FROM_VERT','TURBIDITY','CONDUCTIVITY','PAR') NOT NULL COMMENT "Parameters that can be measured",
  `TR_UOM` set('DEGREES CELSIUS','m','PERCENT','mg/L','pH','cm/s','BEARING DEGREES','FTU','uS','umol/s') NOT NULL COMMENT "Units of measure parameter values are recorded in",
  
  PRIMARY KEY (`TOWS_ENV_ID`),
  
  CONSTRAINT fk_segId3
    FOREIGN KEY (`TOW_SEGMENT_ID`)
    REFERENCES TOW_SEGMENTS(TOW_SEGMENT_ID),
  CONSTRAINT fk_towPOINTS
    FOREIGN KEY (`TOWS_POINTS_ID`)
    REFERENCES TOWS_POINTS(TOWS_POINTS_ID)
)COMMENT='This table stores raw data collected from loggers';
