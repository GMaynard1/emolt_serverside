## Select logger data from the database
commsdat=function(vessel){
  if(vessel=="ALL"){
    dbGetQuery(
      conn=mydb,
      statement="SELECT * FROM vessel_sat WHERE EQUIPMENT_TYPE = 'COMMS_UNIT'"
    )
  } else {
    dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM vessel_sat WHERE VESSEL_NAME = '",
        vessel,
        "' AND EQUIPMENT_TYPE = 'COMMS_UNIT'"
      )
    )
  }
}