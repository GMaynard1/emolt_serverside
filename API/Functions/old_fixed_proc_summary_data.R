old_fixed_proc_summary_data=function(datastring,conn,vessel_id,transmit_time){
  
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
  
  ## Extract the data
  raw=strsplit(
    x=strsplit(
      x=datastring,
      split=","
    )[[1]][3],
    split="eee"
  )
  
  ## Extract mean depth
  mean_depth=as.numeric(substr(raw[[1]][1],1,3))
  
  ## Extract range of depth
  range_depth=as.numeric(substr(raw[[1]][1],4,6))
  
  ## Extract the standard deviation of temperature
  std_temp=as.numeric(substr(raw[[1]][1],nchar(raw[[1]][1])-3,nchar(raw[[1]][1])))/100
  
  ## Extract the mean temperature
  mean_temp=as.numeric(substr(raw[[1]][1],nchar(raw[[1]][1])-7,nchar(raw[[1]][1])-4))/100
  
  ## Extract soak time and convert to minutes
  soak_time=as.numeric(substr(raw[[1]][1],7,nchar(raw[[1]][1])-8))*60
  
  ## Mean time is the temporal midpoint of the haul and is estimated as the 
  ## transmission time - the soak time / 2
  mean_time=transmit_time-minutes(round(soak_time/2,0))
  
  ## Check to see if the record already exists
  old_records=dbGetQuery(
    conn=conn,
    statement=paste0(
      "SELECT * FROM TOWS WHERE VESSEL_ID = ",
      vessel_id,
      " AND MEAN_LATITUDE = ",
      lat,
      " AND MEAN_LONGITUDE = ",
      lon,
      " AND SOAK_TIME = ",
      soak_time,
      " AND MEAN_TIME = '",
      mean_time,
      "'"
    )
  )
  
  ## If the record already exists, print it
  if(nrow(old_records)>0){
    logMessage("Record exists; no action taken",format_delim(old_records,","))
    
    ## Disconnect from databases
    dbDisconnect(conn)
    
    ## Generate API output confirmation message
    return(
      list(
        "STATUS"="Record exists; no action taken"
      )
    )
    
  ## Otherwise, insert a new record and print confirmation
  } else {
    values=paste0(
      vessel_id,
      ",",
      lat,
      ",",
      lon,
      ",",
      soak_time,
      ",'",
      mean_time,
      "'"
    )
    
    logMessage("New record added",values)
    
    ## TOWS update
    dbGetQuery(
      conn=conn,
      statement=paste0(
        "INSERT INTO `TOWS`(`VESSEL_ID`,`MEAN_LATITUDE`,`MEAN_LONGITUDE`,`SOAK_TIME`,`MEAN_TIME`) VALUES (",
        values,
        ")"
      )
    )
    
    tow_id=dbGetQuery(
      conn=conn,
      statement=paste0(
        "SELECT * FROM TOWS WHERE VESSEL_ID = ",
        vessel_id,
        " AND MEAN_TIME = '",
        mean_time,
        "'"
      )
    )$TOW_ID
    
    ## TOWS_SUMMARY update
    dbGetQuery(
      conn=conn,
      statement=paste0(
        "INSERT INTO `TOWS_SUMMARY`(`TOW_ID`,`TS_MEAN_VALUE`,`TS_RANGE_VALUE`,`TS_STD_VALUE`,`TS_PARAMETER`,`TS_UOM`,`TS_SOURCE`,`TS_INSTRUMENT`) VALUES (",
        tow_id,
        ",",
        mean_temp,
        ",NULL,",
        std_temp,
        ",'TEMP','DEGREES CELSIUS','TELEMETRY',NULL),(",
        tow_id,
        ",",
        mean_depth,
        ",",
        range_depth,
        ",NULL,'DEPTH','m','TELEMETRY',NULL)"
      )
    )
    
    ## Calculate distance traveled
    distance=distTrav(vessel_id,transmit_time,conn,lon,lat)
    
    values2=paste0(
      vessel_id,
      ",'SUMMARY_DATA',",
      lat,
      ",",
      lon,
      ",'",
      transmit_time,
      "',",
      distance
    )
    
    logMessage("New record added",values2)
    
    dbGetQuery(
      conn=conn,
      statement=paste0(
        "INSERT INTO `VESSEL_STATUS`(`VESSEL_ID`,`REPORT_TYPE`,`LATITUDE`,`LONGITUDE`,`TIMESTAMP`,`DISTANCE_TRAVELED`) VALUES (",
        values2,
        ")"
      )
    )
    
    ## Disconnect from databases
    dbDisconnect(conn)
    
    ## Return status message
    return(
      list(
        "STATUS"="Data summary record added",
        "VALUES"=values,
        "STATUS"="Status record added",
        "VALUES"=values2
      )
    )
  }
}

