DELIMITER &&
CREATE TRIGGER emolt_dat_refresh
AFTER INSERT 
ON TOWS_SUMMARY FOR EACH ROW
BEGIN
  CALL proc_emolt_dat_refresh();
END&&
DELIMITER ;