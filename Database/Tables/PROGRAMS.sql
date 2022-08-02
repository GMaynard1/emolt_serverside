CREATE TABLE `PROGRAMS` (
  `PROGRAM_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `PROGRAM_NAME` varchar(100) NOT NULL COMMENT 'The human-readable name of the program',
  `START_DATE` datetime NOT NULL COMMENT 'When the program began or is scheduled to begin',
  `END_DATE` datetime COMMENT 'When the program ended (leave NULL for ongoing)',
  `LEAD_CONTACT` integer NOT NULL COMMENT 'References CONTACTS.CONTACT_ID',
  
  PRIMARY KEY (`PROGRAM_ID`),
  
  CONSTRAINT fk_LeadContact 
  FOREIGN KEY (`LEAD_CONTACT`) 
    REFERENCES CONTACTS(CONTACT_ID)
  
) COMMENT='This table is used to explain which flavor(s) of eMOLT each vessel is associated with';
