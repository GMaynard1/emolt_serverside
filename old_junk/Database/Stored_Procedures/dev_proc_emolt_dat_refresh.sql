USE `emolt_dev`;
DROP procedure IF EXISTS `proc_emolt_dat_refresh`;

DELIMETER $$ 
USE `emolt_dev`$$
CREATE PROCEDURE proc_emolt_dat_refresh()
BEGIN
  SELECT * FROM emolt_dat ORDER BY MEAN_TIME INTO OUTFILE '/var/lib/mysql-files/emolt_dat/emolt_dev.tmp' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';
END$$

DELIMETER;