CREATE TABLE `PORTS`
(
  `FIPS_STATE_CODE` varchar(2) NOT NULL COMMENT 'Comes in from FVTR.FVTR_PORTS@sole',
  `FIPS_PLACE_CODE` varchar(5) NOT NULL COMMENT 'Comes in from FVTR.FVTR_PORTS@sole',
  `FIPS_COUNTY_CODE` varchar(3) NOT NULL COMMENT 'Comes in from FVTR.FVTR_PORTS@sole',
  `PORT` varchar(6) COMMENT 'Comes in from FVTR.FVTR_PORTS@sole',
  `PORT_NAME` varchar(60) COMMENT 'Comes in from FVTR.FVTR_PORTS@sole', 
  `STATE_POSTAL` varchar(2) COMMENT 'Comes in from FVTR.FVTR_PORTS@sole',
  `COUNTY_NAME` varchar(30) COMMENT 'Comes in from FVTR.FVTR_PORTS@sole',
  `LATITUDE` decimal(10,5) COMMENT 'Port latitude in decimal degrees. This number is manually generated for the purposes of eMOLT.',
  `LONGITUDE` decimal(10,5) COMMENT 'Port longitude in decimal degrees. This number is manually generated for the purposes of eMOLT.',
  `EMOLT_REGION` set('New Jersey','Rhode Island','New Bedford','Cape Cod','North Shore','Maine','New York','Alaska','Canada') COMMENT 'Administrative regions of eMOLT (i.e., where support staff exist)',

  PRIMARY KEY (`PORT`)
) COMMENT='This table is primarily read in from FVTR.FVTR_PORTS@sole, with the exception of lat/lon and region which much be manually added for each port.';
