## Select logger data from the database
loggerdat=function(vessel,dbconn){
  if(vessel=="ALL"){
    dbGetQuery(
      conn=dbconn,
      statement="SELECT * FROM vessel_mac WHERE EQUIPMENT_TYPE = 'LOGGER'"
    )
  } else {
    dbGetQuery(
      conn=dbconn,
      statement=paste0(
        "SELECT * FROM vessel_mac WHERE VESSEL_NAME = '",
        vessel,
        "' AND EQUIPMENT_TYPE = 'LOGGER'"
      )
    )
  }
}