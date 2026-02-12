CREATE TABLE `SEGMENT_TYPES`(
  `SEGMENT_TYPE` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `SEGMENT_DESCRIPTION` varchar(255) NOT NULL COMMENT 'Description of the type of tow segment this value represents',
  
  PRIMARY KEY (`SEGMENT_TYPE`)
)COMMENT='This table stores the types of segments that tows can be broken into';