CREATE TABLE `TOW_SEGMENTS`(
  `TOW_SEGMENT_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `TOW_SENSOR_ID` integer NOT NULL COMMENT 'Links to the TOWS table',
  `SEGMENT_START_TIME` datetime NOT NULL COMMENT 'The timestamp that delineates the beginning of the segment',
  `SEGMENT_END_TIME` datetime NOT NULL COMMENT 'The timestamp that delineates the end of the segment',
  `SEGMENT_TYPE` integer NOT NULL COMMENT 'Links to the SEGMENT_TYPES table',
  `SEGMENTATION_METHOD` integer NOT NULL COMMENT 'Links to the SEGMENTATION_METHODS table',

  PRIMARY KEY (`SEGMENT_ID`),
  CONSTRAINT fk_tow_sensor_id
    FOREIGN KEY (`TOW_SENSOR_ID`)
    REFERENCES TOW_SENSORS(TOW_SENSOR_ID),
  CONSTRAINT fk_segType
    FOREIGN KEY (`SEGMENT_TYPE`)
    REFERENCES SEGMENT_TYPES(SEGMENT_TYPE),
  CONSTRAINT fk_segMeth
    FOREIGN KEY (`SEGMENTATION_METHOD`)
    REFERENCES SEGMENTATION_METHODS(SEGMENTATION_METHOD),
)COMMENT='This table stores information about when tows can be broken into distinct segments (e.g., downcast vs. retrieval) and how those breakpoints are applied';