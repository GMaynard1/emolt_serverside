CREATE TABLE `SEGMENTATION_METHODS`(
  `SEGMENTATION_METHOD` integer NOT NULL AUTO_INCREMENT COMMENT 'UID for this table',
  `METHOD_NAME` varchar(255) NOT NULL COMMENT 'A name for the method applied (can be a script name)',
  `METHOD_DETAILS` varchar(255) NOT NULL COMMENT 'A link to the GitHub page of the script',
  
  PRIMARY KEY (`SEGMENTATION_METHOD`)
)COMMENT='This table stores descriptions of data processingg methods used to segment tows';