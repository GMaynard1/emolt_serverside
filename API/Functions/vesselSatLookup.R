## Use the IMEI and serial to look up the vessel
vesselSatLookup=function(imei,serial,mydb){
  dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM vessel_sat WHERE HARDWARE_ADDRESS = '",
      imei,
      "' AND SERIAL_NUMBER = '",
      serial,
      "'"
    )
  )$VESSEL_ID
}