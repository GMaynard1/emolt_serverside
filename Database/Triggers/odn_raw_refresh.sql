DELIMITER &&
CREATE TRIGGER odn_raw_refresh
AFTER INSERT 
ON TOWS_RAW FOR EACH ROW
BEGIN
  TRUNCATE TABLE odn_data_raw;
  INSERT INTO odn_data_raw
    SELECT
      zz_odn_depth_raw.VESSEL_ID,
      zz_odn_depth_raw.FMCODE AS GEAR_TYPE,
      zz_odn_depth_raw.TOW_ID,
      zz_odn_depth_raw.TIMESTAMP,
      zz_odn_depth_raw.LATITUDE,
      zz_odn_depth_raw.LONGITUDE,
      zz_odn_depth_raw.DEPTH,
      zz_odn_temp_raw.TEMP
    FROM 
      zz_odn_depth_raw
    INNER JOIN 
      zz_odn_temp_raw
    ON 
      zz_odn_depth_raw.TOW_ID = zz_odn_temp_raw.TOW_ID
      AND
      zz_odn_depth_raw.TIMESTAMP = zz_odn_temp_raw.TIMESTAMP
END&&
DELIMITER ;