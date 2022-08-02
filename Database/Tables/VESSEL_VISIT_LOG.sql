CREATE TABLE `VESSEL_VISIT_LOG`(
  `VISIT_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `VESSEL_ID` integer NOT NULL COMMENT 'References VESSELS.VESSEL_ID. Which vessel was visited.',
  `VISIT_DATE` datetime NOT NULL COMMENT 'The date when the vessel was visited.',
  `LEAD_TECH` integer NOT NULL COMMENT 'Who was the senior technician on site during the visit? References CONTACTS.CONTACT_ID',
  `PORT` varchar(6) NOT NULL COMMENT 'Where the visit took place',
  `VISIT_NOTES` text COMMENT 'Any additional notes about the visit',
  
  PRIMARY KEY (`VISIT_ID`),
  
  CONSTRAINT fk_VisitVesselID
  FOREIGN KEY (`VESSEL_ID`) 
    REFERENCES VESSELS(VESSEL_ID),
  CONSTRAINT fk_VisitPort
  FOREIGN KEY (`PORT`) 
    REFERENCES PORTS(PORT),
  CONSTRAINT fk_LeadTech
  FOREIGN KEY (`LEAD_TECH`)
    REFERENCES CONTACTS(CONTACT_ID)  
) COMMENT='This table records visits of technicians to ports to service eMOLT systems or install new systems.';