CREATE TABLE `EQUIPMENT_CHANGE`(
  `EQUIPMENT_CHANGE_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `START_INVENTORY_ID` integer COMMENT 'The piece of equipment initially on the vessel. NULL if new install.',
  `END_INVENTORY_ID` integer COMMENT 'The piece of equipment installed on the vessel. NULL if equipment removed.',
  `VISIT_ID` integer COMMENT 'Visit ID number for when the install / removal / swap occurred',
  
  PRIMARY KEY (`EQUIPMENT_CHANGE_ID`),
  
  CONSTRAINT fk_invStart
  FOREIGN KEY (`START_INVENTORY_ID`) 
    REFERENCES EQUIPMENT_INVENTORY(INVENTORY_ID),
  CONSTRAINT fk_invEnd
  FOREIGN KEY (`END_INVENTORY_ID`)
    REFERENCES EQUIPMENT_INVENTORY(INVENTORY_ID),
  CONSTRAINT fk_changeVisit
  FOREIGN KEY (`VISIT_ID`)
    REFERENCES VESSEL_VISIT_LOG(VISIT_ID)
) COMMENT='This table tracks equipment installations, change outs, and removals from vessels.'