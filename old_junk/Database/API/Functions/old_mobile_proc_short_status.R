oldMobile_procShortStatus=function(datastring,conn,vessel_id,transmit_time){
  ## Extract latitude
  raw=strsplit(
    x=datastring,
    split=","
  )[[1]][1]
  lat=as.numeric(substr(raw,1,2))+as.numeric(substr(raw,3,nchar(raw)))/60
  
  ## Extract longitude
  raw=strsplit(
    x=datastring,
    split=","
  )[[1]][2]
  lon=(as.numeric(substr(raw,1,2))+as.numeric(substr(raw,3,nchar(raw)))/60)*-1
  
  ## Round latitude and longitude
  lat=round(lat,5)
  lon=round(lon,5)
  
  ## Calculate distance traveled
  distance=distTrav(vessel_id,transmit_time,conn,lon,lat)
  
  ## Check to see if the record already exists
  old_records=dbGetQuery(
    conn=conn,
    statement=paste0(
      "SELECT * FROM VESSEL_STATUS WHERE VESSEL_ID = ",
      vessel_id,
      " AND LATITUDE = ",
      lat,
      " AND LONGITUDE = ",
      lon,
      " AND TIMESTAMP = '",
      transmit_time,
      "'"
    )
  )
  
  ## If the record already exists, print it
  if(nrow(old_records)>0){
    logMessage("Record exists; no action taken",format_delim(old_records,","))
    dbDisconnect(conn)
  return(
    list(
      "STATUS"="Record exists; no action taken"
    )
  )
  ## Otherwise, insert a new record and print confirmation
  } else {
    values=paste0(
      vessel_id,
      ",'SHORT_STATUS',",
      lat,
      ",",
      lon,
      ",'",
      transmit_time,
      "',",
      distance
    )
    logMessage("New record added",values)
    dbGetQuery(
      conn=conn,
      statement=paste0(
        "INSERT INTO `VESSEL_STATUS`(`VESSEL_ID`,`REPORT_TYPE`,`LATITUDE`,`LONGITUDE`,`TIMESTAMP`,`DISTANCE_TRAVELED`) VALUES (",
        values,
        ")"
      )
    )
    
    ## Disconnect from database
    dbDisconnect(conn)
    
    ## Return status message
    return(
      list(
        "STATUS"="Status record added",
        "VALUES"=values
      )
    )
  }
}
