CREATE TABLE `VESSELS` (
  `VESSEL_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `VESSEL_NAME` varchar(50) NOT NULL COMMENT 'This field is not unique and should not be used exclusively to identify vessels',
  `PORT` varchar(6) NOT NULL COMMENT 'This field is the standard PORT code used by NEFSC / ACCSP available at FVTR.FVTR_PORTS@sole',
  `OWNER` integer COMMENT 'This field references CONTACTS.CONTACT_ID and identifies the owner of a vessel',
  `OPERATOR` integer COMMENT 'This field references CONTACTS.CONTACT_ID and identifies the operator of a vessel',
  `PRIMARY_CONTACT` integer NOT NULL COMMENT 'This field references CONTACTS.CONTACT_ID and identifies the best contact person for a vessel which could be the owner, the operator, or a fleet manager, Study Fleet tech, etc.',
  `TECHNICAL_CONTACT` integer NOT NULL COMMENT 'This field references CONTACTS.CONTACT_ID and identifies the best tech support person for a vessel which could be the owner, the operator, or a fleet manager, Study Fleet tech, etc.',
  `PRIMARY_GEAR` varchar(6) COMMENT 'This field is the type of gear fished by the vessel most often and is the concatenation of ACCSP and VTR gear codes used to map gears between the two data sets available at FVTR.FVTR_GEAR_CODES@sole',
  `PRIMARY_FISHERY` varchar(50) COMMENT 'The primary fishery prosecuted by the vessel',
  `HULL_NUMBER` varchar(30) COMMENT 'The vessel number issued by the federal or state government',
  
  PRIMARY KEY (`VESSEL_ID`),
  
  CONSTRAINT fk_Port
  FOREIGN KEY (`PORT`) 
    REFERENCES PORTS(PORT),
  CONSTRAINT fk_Owner
  FOREIGN KEY (`OWNER`)
    REFERENCES CONTACTS(CONTACT_ID),
  CONSTRAINT fk_Operator
  FOREIGN KEY (`OPERATOR`)
    REFERENCES CONTACTS(CONTACT_ID),
  CONSTRAINT fk_PrimaryContact
  FOREIGN KEY (`PRIMARY_CONTACT`)
    REFERENCES CONTACTS(CONTACT_ID),
  CONSTRAINT fk_TechnicalContact
  FOREIGN KEY (`TECHNICAL_CONTACT`)
    REFERENCES CONTACTS(CONTACT_ID),
  CONSTRAINT fk_PrimaryGear
  FOREIGN KEY(`PRIMARY_GEAR`)
    REFERENCES GEAR_CODES(GEAR_CODE)
) COMMENT='This table stores information about vessels involved in the program, who owns and operates them, where they are based, and what fisheries they participate in.';