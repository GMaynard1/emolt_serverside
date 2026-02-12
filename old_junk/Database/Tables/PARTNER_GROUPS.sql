CREATE TABLE `PARTNER_GROUPS` (
  `PARTNER_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'A unique identifier used in this database only',
  `PARTNER_NAME` varchar(100) NOT NULL COMMENT 'Organization name',
  `PARTNER_STREET` varchar(100) COMMENT 'Partner street address',
  `PARTNER_CITY` varchar(50) COMMENT 'City where mailing address is located',
  `PARTNER_STATE` varchar(2) COMMENT 'Two character abbreviation of state or province used by postal service',
  `PARTNER_ZIP` varchar(6) COMMENT 'Postal code, 5 characters for USA and 6 for Canada',
  `PARTNER_PHONE` varchar(10) COMMENT 'Phone number in format xxxxxxxxxx',
  `PARTNER_EMAIL` varchar(100) COMMENT 'Email address of partner organization',
  
  PRIMARY KEY(`PARTNER_ID`)
) COMMENT='This table stores contact information for industry associations, fishing companies, research institutions, etc. that eMOLT participants are affiliated with.';
