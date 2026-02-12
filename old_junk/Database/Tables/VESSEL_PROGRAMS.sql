CREATE TABLE `VESSEL_PROGRAM` (
  `VP_RECORD_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `VESSEL_ID` integer NOT NULL COMMENT 'References VESSELS.VESSEL_ID',
  `PROGRAM_ID` integer NOT NULL COMMENT 'References PROGRAMS.PROGRAM_ID',
  `VP_START_DATE` datetime NOT NULL COMMENT 'The approximate date when the vessel joined a particular program',
  `VP_END_DATE` datetime COMMENT 'The approximaate date when the vessel left a particular program (NULL for still active)',
  
  PRIMARY KEY(`VP_RECORD_ID`),
  
  CONSTRAINT fk_vp_vid
  FOREIGN KEY (`VESSEL_ID`) 
    REFERENCES VESSELS(VESSEL_ID),
  CONSTRAINT fk_vp_pid
  FOREIGN KEY (`PROGRAM_ID`) 
    REFERENCES PROGRAMS(PROGRAM_ID)
) COMMENT='This table stores information tying vessels to specific programs. A single vessel may participate in multiple programs over time.';