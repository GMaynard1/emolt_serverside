CREATE TABLE `TOWS_SUMMARY`(
  `TS_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `TOW_ID` integer NOT NULL COMMENT 'Ties summary data to a tow',
  `TS_MEAN_VALUE` decimal(10,5) NOT NULL COMMENT 'Mean value of parameter over tow duration',
  `TS_RANGE_VALUE` decimal(10,5) NULL COMMENT 'Absolute value of maximum observed value minus minimum observed value over the tow duration',
  `TS_STD_VALUE` decimal(10,5) NULL COMMENT 'Standard deviation of parameter over tow duration',
  `TS_PARAMETER` set('TEMP','DEPTH','DO','PH','SPEED','DIR','N_VELO','E_VELO','YAW','PITCH','ROLL','HEADING','TILT_FROM_VERT','TURBIDITY','CONDUCTIVITY','PAR') NOT NULL COMMENT "Parameters that can be measured",
  `TS_UOM` set('DEGREES CELSIUS','m','PERCENT','mg/L','pH','cm/s','BEARING DEGREES','FTU','uS','umol/s') NOT NULL COMMENT "Units of measure parameter values are recorded in",
  `TS_SOURCE` set('TELEMETRY','CALCULATED') NULL COMMENT 'Whether the values were delivered from the field by satellite or calculated after the fact.',
  
  PRIMARY KEY (`TS_ID`),
  
  CONSTRAINT fk_towId3
    FOREIGN KEY (`TOW_ID`) 
      REFERENCES TOWS(TOW_ID)

)COMMENT='This table stores summary values of observations from individual tows or hauls of fishing gear. Tow and haul are used to mean the same thing, although in common parlance, "tows" are taken with mobile gear and "hauls" are made with fixed gear. Both gear types "soak" in the water.';