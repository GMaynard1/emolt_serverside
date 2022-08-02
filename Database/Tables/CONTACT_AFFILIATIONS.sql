CREATE TABLE `CONTACT_AFFILIATIONS`(
  `AFFILIATION_ID`integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `PARTNER_ID` integer NOT NULL COMMENT 'References PARTNER_GROUPS.PARTNER_ID',
  `CONTACT_ID` integer NOT NULL COMMENT 'References CONTACTS.CONTACT_ID',
  
  PRIMARY KEY (`AFFILIATION_ID`),
  
  CONSTRAINT fk_pa_pid
  FOREIGN KEY (`PARTNER_ID`) 
    REFERENCES PARTNER_GROUPS(PARTNER_ID),
  CONSTRAINT fk_pa_cid
  FOREIGN KEY (`CONTACT_ID`) 
    REFERENCES CONTACTS(CONTACT_ID)  
) COMMENT='This table links eMOLT participants to industry associations, fishing companies, research institutions, etc.';