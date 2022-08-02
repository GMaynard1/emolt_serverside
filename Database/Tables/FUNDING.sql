CREATE TABLE `FUNDING` (
  `FUNDING_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `FUNDING_AGENCY` varchar(50) NOT NULL COMMENT 'Human readable identifier of funding agency',
  `START_DATE` datetime COMMENT 'When the funding becomes available',
  `END_DATE` datetime COMMENT 'When the funding should be used by',
  `FUNDING_AMOUNT_USD` integer NOT NULL COMMENT 'How much funding was received (in US Dollars)',
  `PROPOSAL_LINK` varchar(255) COMMENT 'Google drive link to funding proposal',
  
  PRIMARY KEY (`FUNDING_ID`)
) COMMENT='This table stores information that will assist in tracking how eMOLT is funded';