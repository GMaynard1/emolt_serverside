USE `emolt_dev`;
DROP procedure IF EXISTS `proc_emolt_dat_refresh`;

DELIMETER $$ 
USE `emolt_dev`$$
CREATE PROCEDURE proc_emolt_dat_refresh()
BEGIN
  TABLE emolt_dat INTO OUTFILE '/var/lib/mysql-files/emolt.dat' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';
END$$

DELIMETER;