## Select logger data from the database
loggerdat=function(vessel,dbconn){
  if(vessel=="ALL"){
    start=dbGetQuery(
      conn=dbconn,
      statement="SELECT * FROM zz_mac_start2"
    )
    start$Action='REMOVE'
    end=dbGetQuery(
      conn=dbconn,
      statement="SELECT * FROM zz_mac_end2"
    )
    end$Action="ADD"
    data=rbind(start,end)
    return(data)
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
