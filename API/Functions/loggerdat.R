## Select logger data from the database
loggerdat=function(vessel){
  if(vessel=="ALL"){
    dbGetQuery(
      conn=mydb,
      statement="SELECT * FROM vessel_mac WHERE EQUIPMENT_TYPE = 'LOGGER'"
    )
  } else {
    dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM vessel_mac WHERE VESSEL_NAME = '",
        vessel,
        "' AND EQUIPMENT_TYPE = 'LOGGER'"
      )
    )
  }
}