CREATE TABLE `SEGMENTS`(
  `SEGMENT_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `TOW_ID` integer NOT NULL COMMENT 'Links to the TOWS table',
  `SEGMENT_START_TIME` datetime NOT NULL COMMENT 'The timestamp that delineates the beginning of the segment',
  `SEGMENT_END_TIME` datetime NOT NULL COMMENT 'The timestamp that delineates the end of the segment',
  `SEGMENT_TYPE` integer NOT NULL COMMENT 'Links to the SEGMENT_TYPES table',
  `SEGMENTATION_METHOD` integer NOT NULL COMMENT 'Links to the SEGMENTATION_METHODS table',
  
  PRIMARY KEY (`SEGMENT_ID`),
  
  CONSTRAINT fk_towId
    FOREIGN KEY (`TOW_ID`)
    REFERENCES TOWS(TOW_ID),
  CONSTRAINT fk_segType
    FOREIGN KEY (`SEGMENT_TYPE`)
    REFERENCES SEGMENT_TYPES(SEGMENT_TYPE),
  CONSTRAINT fk_segMeth
    FOREIGN KEY (`SEGMENTATION_METHOD`)
    REFERENCES SEGMENTATION_METHODS(SEGMENTATION_METHOD)
)COMMENT='This table stores information about when tows can be broken into distinct segments (e.g., downcast vs. retrieval) and how those breakpoints are applied';