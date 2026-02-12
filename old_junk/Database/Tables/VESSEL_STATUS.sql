/*
* Title: VESSEL_STATUS.sql
* Author: George Maynard
* Contact: george.maynard@noaa.gov
* Purpose: Creates a table that can store vessel status reports to allow better diagnostics and tracking of hardware performance
*/

CREATE TABLE `VESSEL_STATUS`(
  `REPORT_ID` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `VESSEL_ID` integer NOT NULL COMMENT 'Ties status report to vessel',
  `REPORT_TYPE` set('SUMMARY_DATA','RAW_DATA','SHORT_STATUS','LONG_STATUS','MANUAL') NOT NULL COMMENT 'The type of status report. Data means that data were transmitted. Status means an automated status report. Manual means the report was triggered manually by an end user',
  `LATITUDE` decimal(10,5) NOT NULL COMMENT 'Latitude of status report',
  `LONGITUDE` decimal(10,5) NOT NULL COMMENT 'Longitude of status report',
  `TIMESTAMP` datetime NOT NULL COMMENT 'When the reportt was transmitted',
  `GPS_SATS` int NULL COMMENT 'The number of GPS satellites in view',
  `IRID_SATS` int NULL COMMENT 'The number of iridium satellites in view (if available)',
  `UPTIME` int NULL COMMENT 'The number of minutes the system has been powered on',
  `CELL_STRENGTH` decimal(10,5) NULL COMMENT 'The signal strength of the cellular network (if available)',
  `WIFI_STRENGTH` decimal(10,5) NULL COMMENT 'The signal strength of the wifi network (if available)',
  `LAST_DOWNLOAD` datetime NULL COMMENT 'The most recent successful download from a probe',
  `DATA_USAGE` decimal(10,2) NULL COMMENT 'Amount of data (MB) transmitted via cellular network since the last status report (if available)',
  `DISTANCE_TRAVELED` decimal(10,2) NULL COMMENT 'Straight line distance traveled (km) from location of last status report',
  
  PRIMARY KEY (`REPORT_ID`),
  
  CONSTRAINT fk_ves_rep_ID
    FOREIGN KEY (`VESSEL_ID`)
      REFERENCES VESSELS(VESSEL_ID)
)COMMENT='This table stores information about where vessels are located and indicators of the status of different systems onboard';