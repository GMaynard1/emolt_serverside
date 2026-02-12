CREATE TABLE `GEAR_CODES`(
  `GEAR_CODE` varchar(6) NOT NULL COMMENT 'Concatenation of ACCSP and VTR gear codes used to map gears between the two data sets',
  `COMMON` varchar(80) COMMENT 'How gears are referred to in the Northeastern United States',
  `ACCSP_GEAR_CODE` varchar(3) NOT NULL COMMENT 'ACCSP gear code',
  `VTR_GEAR_CODE` varchar(3) COMMENT 'VTR gear code',
  `VTR_GEAR_NAME` varchar(80) COMMENT 'VTR gear code description',
  `ACCSP_GEAR_NAME` varchar(40) NOT NULL COMMENT 'ACCSP gear code description',
  `NEGEAR` varchar(3) COMMENT 'Gear coding equivalent for CFDBS an OBDBS',
  `FMCODE` varchar(1) NOT NULL COMMENT 'Gear category type indicator; F=fixed, M=mobile, O=other',
  `ISSCFG_CODE_EN` varchar(80) COMMENT 'English language ISSCFG gear description',
  `CODE` varchar(5) COMMENT 'ISSCFG gear code',
  `GEAR_L1_NAME` varchar(40) 'General ISSCFG category',
  `GEAR_L1_CODE` varchar(5) 'General ISSCFG category gear code',
  
  PRIMARY KEY (`GEAR_CODE`)
) COMMENT='This table is columns 1-4, 6, 27, and 30 from FVTR.FVTR_GEAR_CODES. It contains both human readable and standard codes for all gear types categorized by ACCSP and NEFSC. It also includes values from the International Standard Statistical Classification of Fishing Gears (ISSCFG)'; 