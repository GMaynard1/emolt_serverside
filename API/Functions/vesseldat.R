## Get Vessel Data
vesseldat=function(vessel,dbconn){
  dbGetQuery(
    conn=dbconn,
    statement=paste0(
      "SELECT * FROM VESSELS INNER JOIN GEAR_CODES ON VESSELS.PRIMARY_GEAR = GEAR_CODES.GEAR_CODE WHERE VESSEL_NAME = '",
      vessel,
      "'"
    )
  )
}