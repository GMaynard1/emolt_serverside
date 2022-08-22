# plumber.R
## Load necessary libraries
require(config)
require(geosphere)
require(jsonlite)
require(lubridate)
require(plumber)
require(readr)
require(reticulate)
require(RMySQL)
require(wkb)

## Ensure enough database connections are available for multiple vessels
## reporting simultaneously
MySQL(max.con=50)

## Vector of functions to read in
functions=c(
  'checkTransmissionType.R',
  'commsdat.R',
  'create_py_dict.R',
  'dbConnector.R',
  'dbDisconnectAll.R',
  'distTrav.R',
  'loggerdat.R',
  'logMessage.R',
  'new_procShortStatus.R',
  'new_proc_summary_data.R',
  'standard_mac.R',
  'vessel_name.R',
  'vesseldat.R',
  'vesselSatLookup.R'
)

## Read in functions and database configuration values
if(Sys.info()[["nodename"]]=="emoltdev"){
  db_config=config::get(file="/etc/plumber/config.yml")$dev_local
  db_config2=config::get(file="/etc/plumber/config.yml")$add_local_dev
  for(i in 1:length(functions)){
    source(
      paste0(
        "/etc/plumber/Functions/",
        functions[i]
      )
    )
  }
} else {
  db_config=config::get(file="C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/config.yml")$dev_remote
  db_config2=config::get(file="C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/config.yml")$add_remote_dev
  for(i in 1:length(functions)){
    source(
      paste0(
        "C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/Functions/",
        functions[i]
      )
    )
  }
}



#* @apiTitle eMOLT dev API
#* @apiDescription This is the development API for the eMOLT project.
#* @apiContact list(name="API Support",email="george.maynard@noaa.gov") 

#* Import information about a new logger
#* @param loggerdat
#* @post /loggerload
function(loggerdat){
  ## Create a read only database connection
  mydb = dbConnector(db_config)
  
  ## Create a read-write database connection
  conn=dbConnector(db_config2)
  
  ## Read in the json object
  loggerdat=parse_json(loggerdat)
  
  ## Lookup logger by serial number
  loggerExists=loggerdat$SN%in%dbGetQuery(
    conn=mydb,
    statement="SELECT * FROM EQUIPMENT_INVENTORY WHERE EQUIPMENT_TYPE = 'LOGGER'"
  )$SERIAL_NUMBER
  
  ## If the logger already exists, return an error
  if(loggerExists){
    return("Logger already exists. Please use the 'UpdateLogger' function if you wish to edit an existing logger.")
    dbDisconnectAll()
    break()
  }
  ## If the MAC address doesn't have the right number of characters, return an error
  if(nchar(loggerdat$MAC)%in%c(17,12)==FALSE){
    return("MAC address has an incorrect number of characters. Please try xx:xx:xx:xx:xx:xx")
    dbDisconnectAll()
    break()
  }
  ## Attempt to standardize the MAC address
    MAC=standard_mac(loggerdat$MAC)
    if(MAC=="ERROR"){
      return("MAC address improperly formatted. Please try xx:xx:xx:xx:xx:xx")
      dbDisconnectAll()
      break()
    }  
    ## Reformat location
    loggerdat$Location=ifelse(
      loggerdat$Location==1,
      "HOME",
      ifelse(
        loggerdat$Location==2,
        "LAB",
        ifelse(
          loggerdat$Location==3,
          "VESSEL",
          ifelse(
            loggerdat$Location==4,
            "MANUFACTURER",
            ifelse(
              loggerdat$Location==5,
              "LOST",
              ifelse(
                loggerdat$Location==6,
                "DECOMMISSIONED",
                "UNK"
              )
            )
          )
        )
      )
    )
    if(loggerdat$Location=="UNK"){
      return("Logger location invalid, please select a number from the provided list")
      dbDisconnectAll()
      break()
    }
    ## Look up custodian
    custodian=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM CONTACTS WHERE FIRST_NAME = '",
        loggerdat$cFirst_name,
        "' AND LAST_NAME = '",
        loggerdat$cLast_name,
        "'"
      )
    )$CONTACT_ID
    if(length(custodian)!=1){
      custodian=dbGetQuery(
        conn=mydb,
        statement=paste0(
          "SELECT * FROM CONTACTS WHERE FIRST_NAME LIKE '%",
          loggerdat$cFirst_name,
          "%' OR LAST_NAME LIKE '%",
          loggerdat$cLast_name,
          "%'"
        )
      )
      dbDisconnectAll()
      return(
        paste0(
          "No custodian found. Please try again. Similar entries include: ",
          paste(
            custodian$FIRST_NAME,
            custodian$LAST_NAME
          )
        )
      )
      break()
    }
    ## Check which optional variables are present to form the query
    opt=""
    optvals=""
    if(is.null(loggerdat$Software_version)==FALSE){
      opt=paste0(opt,",`SOFTWARE_VERSION`")
      optvals=paste0(optvals,",'",loggerdat$Software_version,"'")
    }
    if(is.null(loggerdat$Firmware_version)==FALSE){
      opt=paste0(opt,",`FIRMWARE_VERSION`")
      optvals=paste0(optvals,",'",loggerdat$Firmware_version,"'")
    }
    if(is.null(loggerdat$Purchase_date)==FALSE){
      opt=paste0(opt,",`PURCHASE_DATE`")
      optvals=paste0(optvals,",'",loggerdat$Purchase_date,"'")
    }
    if(is.null(loggerdat$Purchase_price)==FALSE){
      opt=paste0(opt,",`PURCHASE_PRICE`")
      optvals=paste0(optvals,",",loggerdat$Purchase_price)
    }
    ## Form the insert statement
    statement=paste0(
      "INSERT INTO `EQUIPMENT_INVENTORY`(`INVENTORY_ID`,`SERIAL_NUMBER`,`EQUIPMENT_TYPE`,`MAKE`,`MODEL`,`CUSTODIAN`,`CURRENT_LOCATION`",
      opt,
      ") VALUES ( 0,'",
      loggerdat$SN,
      "','LOGGER','",
      toupper(loggerdat$Make),
      "','",
      toupper(loggerdat$Model),
      "',",
      custodian,
      ",'",
      loggerdat$Location,
      "'",
      optvals,
      ")"
    )
    ## Run the statement
    dbGetQuery(
      conn=conn,
      statement=statement
    )
    ## Update the hardware address table
    eid=dbGetQuery(
      conn=conn,
      statement=paste0(
        "SELECT * FROM EQUIPMENT_INVENTORY WHERE SERIAL_NUMBER = '",
        loggerdat$SN,
        "' AND MAKE = '",
        loggerdat$Make,
        "' AND MODEL = '",
        loggerdat$Model,
        "'")
    )$INVENTORY_ID
    dbGetQuery(
      conn=conn,
      statement=paste0(
        "INSERT INTO `HARDWARE_ADDRESSES`(`HARDWARE_ID`,`INVENTORY_ID`,`ADDRESS_TYPE`,`HARDWARE_ADDRESS`) VALUES (0,",
        eid,
        ",'MAC','",
        MAC,
        "')"
      )
    )
    response=list(
      "Status"=paste0("New logger added at ", Sys.time()),
      "Summary"=dbGetQuery(
        conn=mydb,
        statement=paste0(
          "SELECT * FROM EQUIPMENT_INVENTORY INNER JOIN HARDWARE_ADDRESSES ON WHERE SERIAL_NUMBER = '",
          loggerdat$SN,
          "' AND MAKE = '",
          loggerdat$Make,
          "' AND MODEL = '",
          loggerdat$Model,
          "'"
        )
      ),
      "MAC"=MAC
    )
    dbDisconnectAll()
    return(response)
}

#* Get logger MAC addresses associated with vessels
#* @param vessel The vessel of interest
#* @get /readMAC
function(vessel="ALL"){
  ## Create a read only connection to the database
  mydb=dbConnector(db_config)
  
  ## Standardize vessel name
  vessel=vessel_name(vessel)
  
  ## Download and display data
  loggerdat(vessel,mydb)
  
  ## Disconnect from the database
  dbDisconnectAll()
}

#* Create and export control file for Lowell logger system during vessel setup
#* @param vessel The vessel you'd like to create a control file for
#* @serializer cat
#* @get /getControl_File_Lowell
function(vessel){
  ## Create a read only connection to the database
  mydb=dbConnector(db_config)
  
  ## Standardize the vessel name
  vessel=vessel_name(vessel)
  
  ## Query the logger metadata out of the database
  loggerdat=loggerdat(vessel,mydb)
  
  ## Query the comms unit metadata out of the database
  commsdat=commsdat(vessel,mydb)
  
  ## Query the vessel data out of the database
  vesseldat=vesseldat(vessel,mydb)
  
  ## Convert gear to the correct format
  gear=vesseldat$FMCODE
  if(gear=="F"){
    gear="fixed"
  } else {
    if(gear=="M"){
      gear="mobile"
    } else {
      gear="other"
    }
  }
  
  ## Convert comms make to the correct format
  if(commsdat$MAKE=="ROCKBLOCK"){
    transmitter='rock'
  } else {
    if(commsdat$MAKE=="AP3"){
      transmitter='ap3'
    }
  }
  ## Create a filename based on the vessel name and date
  if(Sys.info()[["nodename"]]=="emoltdev"){
    filename=paste0(
      "/etc/plumber/control_files/",
      vessel,
      "_",
      Sys.Date(),
      "_control_file.txt"
    )
  } else {
    filename=paste0(
      vessel,
      "_",
      Sys.Date(),
      "_control_file.txt"
    )
  }
  
  ## Use tab separated strings to create the file
  file.create(filename)
  fileconn=file(filename)
  contents=c(
    paste0(10,"\t# logger time range(minutes), set it to 5 , during the test. Set it to the shortest haul time. Unit Minute"),
    paste0(3,"\t# Fathom, Set to 0 for test, set to 15 after the test"),
    "yes\t# Set to 'yes', if there is a transmitter, otherwise, set to 'no'",
    paste0(loggerdat$HARDWARE_ADDRESS,"\t# Put logger Mac address in"),
    paste0(gear,"\t# boat type , mobile or fixed"),
    paste0(vesseldat$EMOLT_NUM,"\t# Vessel Number"),
    paste0(vesseldat$VESSEL_NAME,"\t# Vessel Name"),
    "no\t# record tilt data?",
    "60\t#",
    paste0(transmitter,'\t# transmitter name')
  )
  writeLines(
    text=contents,
    con=fileconn,
    sep="\n"
  )
  close(fileconn)
  ## Read in completed file
  y=read_file(filename)
  dbDisconnectAll()
  ## Return the text as a file to the end user
  as_attachment(y,"control_file.txt")
}

#* Create and export control file for Moana logger system during vessel setup
#* @param vessel The vessel you'd like to create a control file for
#* @serializer cat
#* @get /getControl_File
function(vessel){
  ## Create a read-only connection to the database
  mydb=dbConnector(db_config)
  
  ## Standardize the vessel name to all uppercase, no underscore, remove the 
  ## leading characters F/V if they exist
  vessel=vessel_name(vessel)
  
  ## Query the logger metadata out of the database
  loggerdat=loggerdat(vessel,mydb)
  
  ## Query the gear type out of the database
  gear=vesseldat(vessel,mydb)$FMCODE
  
  ## Convert gear to the correct format
  if(gear=="F"){
    gear="fixed"
  } else {
    if(gear=="M"){
      gear="mobile"
    } else {
      gear="other"
    }
  }
  ## Create a filename based on the vessel name and date
  if(Sys.info()[["nodename"]]=="emoltdev"){
    filename=paste0(
      "/etc/plumber/control_files/",
      vessel,
      "_",
      Sys.Date(),
      "_setup_rtd.py"
    )
  } else {
    filename=paste0(
      vessel,
      "_",
      Sys.Date(),
      "_setup_rtd.py"
    )
  }
  ## Create the metadata dictionary
  keys=c(
    "'time_range'",
    "'Fathom'",
    "'transmitter'",
    "'mac_addr'",
    "'gear_type'",
    "'vessel_num'",
    "'vessel_name'",
    "'tilt'"
  )
  values=c(
    1,
    .1,
    "'yes'",
    paste0("'",loggerdat$HARDWARE_ADDRESS,"'"),
    paste0("'",gear,"'"),
    loggerdat$EMOLT_NUM,
    paste0("'",vessel,"'"),
    "'no'"
  )
  create_py_dict(keys,values)
  ## Write the metadata dictionary to the file
  py_run_string("import json")
  py_run_string(
    paste0(
      "with open('",
      filename,
      "','w') as fp: fp.write('metadata = ')"
    )
  )
  py_run_string(
    paste0(
      "with open('",
      filename,
      "','a') as fp: json.dump(data,fp)"
      )
  )
  ## Create the parameters dictionary
  keys=c(
    "'path'",
    "'sensor_type'",
    "'time_diff_nke'",
    "'tem_unit'",
    "'depth_unit'",
    "'local_time'"
  )
  values=c(
    "'/home/pi/rtd_global/'",
    paste0("'",loggerdat$MAKE,"'"),
    0,
    "'Fahrenheit'",
    "'Fathoms'",
    -4
  )
  create_py_dict(keys,values)
  ## Write the parameters dictionary to file
  py_run_string(
    paste0(
      "with open('",
      filename,
      "','a') as fp: fp.write(",
      '"""\nparameters = """)'
    )
  )
  py_run_string(
    paste0(
      "with open('",
      filename,
      "','a') as fp: json.dump(data,fp)"
    )
  )
  ## Read in completed file
  y=read_file(filename)
  dbDisconnectAll()
  ## Return the text as a file to the end user
  as_attachment(y,"setup_rtd.py")
}

#* Record status updates and haul average data transmissions via satellite
#* @param data A string of hex data from a ROCKBLOCK
#* @param serial The serial number of the ROCKBLOCK
#* @param imei The satellite transmitter's International Mobile Equipment Identity
#* @param transmit_time time of transmission in UTC
#* @post /getRock_API
function(data,serial,imei,transmit_time){
  ## Print startup message to log
  logMessage("Processing satellite transmission",data)
  
  ## Close all existing connections
  dbDisconnectAll()
  
  ## Create a read only database connection
  mydb = dbConnector(db_config)
  
  ## Create a read-write database connection
  conn = dbConnector(db_config2)
  
  ## Convert transmission time to POSIX format
  transmit_time = ymd_hms(transmit_time)
  
  ## Identify the vessel using information from the satellite transmitter
  vessel_id = vesselSatLookup(imei,serial,mydb)
  
  ## Decode the data
  ## Convert the data from hex to character
  datastring=rawToChar(
    as.raw(
      strtoi(
        wkb::hex2raw(data),
        16L
      )
    )
  )
  
  ## Check to see if the data is a status report or actual fishing
  datType=checkTransmissionType(data)
  
  logMessage("Transmission Type Identified",datType)
  
  ## Process the data according to the transmission type
  
  if(datType=="SHORT_STATUS"){
    new_procShortStatus(datastring,conn,vessel_id,transmit_time)
  } else {
    if(datType=="SUMMARY_DATA"){
    new_proc_summary_data(datastring,conn,vessel_id,transmit_time) 
    }
  }
  
  ## Disconnect from the databases
  dbDisconnectAll()
}

#* Record status updates and haul average data transmissions via satellite (old style, mobile gear only)
#* @param data A string of hex data from a ROCKBLOCK
#* @param serial The serial number of the ROCKBLOCK
#* @param imei The satellite transmitter's International Mobile Equipment Identity
#* @param transmit_time time of transmission in UTC
#* @post /getRock_API_old_mobile
function(data,serial,imei,transmit_time){
  ## Print startup message to log
  message(
    paste0(
      "Processing old format mobile gear transmission at ",
      Sys.time(),
      "\nData = ",
      data
    )
  )
  ## Clear all existing connections
  dbDisconnectAll()
  ## Connect to database
  mydb = dbConnector(db_config)
  ## Identify the vessel
  vessel_id=vesselSatLookup(imei,serial,mydb)
  ## Decode the data
  ## Convert the data from hex to character
  datastring=rawToChar(
    as.raw(
      strtoi(
        wkb::hex2raw(data),
        16L
      )
    )
  )
  ## Check to see if the data is a status report or actual fishing
  if(strsplit(
    x=datastring,
    split=","
  )[[1]][3]=="0000000000"){
    ## Extract latitude
    raw=strsplit(
      x=datastring,
      split=","
    )[[1]][1]
    lat=as.numeric(substr(raw,1,2))+as.numeric(substr(raw,3,nchar(raw)))/60
    raw=strsplit(
      x=datastring,
      split=","
    )[[1]][2]
    lon=(as.numeric(substr(raw,1,2))+as.numeric(substr(raw,3,nchar(raw)))/60)*-1
    ## Collect the most recent status report
    mr=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM VESSEL_STATUS WHERE TIMESTAMP=(SELECT MAX(TIMESTAMP) FROM VESSEL_STATUS WHERE VESSEL_ID = ",
        vessel_id,
        " AND TIMESTAMP < '",
        transmit_time,
        "')"
      )
    )
    ## Calculate distance traveled
    distance=ifelse(
      nrow(mr)==0||is.null(mr$LATITUDE)||is.null(mr$LONGITUDE),
      "NULL",
      distHaversine(
        c(lon,lat),
        c(mr$LONGITUDE,mr$LATITUDE)
      )/1000
    )
    ## Insert a record into the vessel_status table
    dbGetQuery(
      conn=mydb,
      statement=paste0(
        "INSERT INTO `VESSEL_STATUS`(`VESSEL_ID`,`REPORT_TYPE`,`LATITUDE`,`LONGITUDE`,`TIMESTAMP`,`DISTANCE_TRAVELED`) VALUES (",
        vessel_id,
        ",'SHORT_STATUS',",
        lat,
        ",",
        lon,
        ",'",
        ymd_hms(transmit_time),
        "',",
        distance,
        ")"
      )
    )
    newrecord=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM VESSEL_STATUS WHERE VESSEL_ID = ",
        vessel_id,
        " AND TIMESTAMP = '",
        ymd_hms(transmit_time),
        "'"
      )
    )
    message(toJSON(newrecord))
    dbDisconnectAll()
    return(
      list(
        "STATUS"="Status record added",
        "RECORD"=newrecord
      )
    )
  }
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
  ## Extract mean depth
  mean_depth=as.numeric(substr(strsplit(datastring,",")[[1]][3],1,3))
  ## Extract range of depth
  range_depth=as.numeric(substr(strsplit(datastring,",")[[1]][3],4,6))
  ## Extract soak time in minutes
  soak_time=as.numeric(substr(strsplit(datastring,",")[[1]][3],7,9))
  ## Mean time is the temporal midpoint of the haul and is estimated as the transmission time - the soak time / 2
  transmit_time=ymd_hms(as.character(transmit_time))
  mean_time=transmit_time-minutes(round(soak_time/2,0))
  ## Extract the mean temperature
  mean_temp=as.numeric(substr(strsplit(datastring,",")[[1]][3],10,13))/100
  std_temp=as.numeric(substr(strsplit(datastring,",")[[1]][3],14,17))/100
  ## Check to see if the record already exists
  record=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM TOWS WHERE VESSEL_ID = ",
      vessel_id,
      " AND MEAN_LATITUDE = ",
      round(lat,5),
      " AND MEAN_LONGITUDE = ",
      round(lon,5),
      " AND SOAK_TIME = ",
      soak_time,
      " AND MEAN_TIME = '",
      mean_time,
      "'"
    )
  )
  if(nrow(record)!=0){
    dbDisconnectAll()
    return("Record already exists, no new record added")
  }
  ## Create the INSERT statement to load the data
  conn=dbConnector(db_config2)
  dbGetQuery(
    conn=conn,
    statement=paste0(
      "INSERT INTO `TOWS`(`VESSEL_ID`,`MEAN_LATITUDE`,`MEAN_LONGITUDE`,`SOAK_TIME`,`MEAN_TIME`) VALUES (",
      vessel_id,
      ",",
      lat,
      ",",
      lon,
      ",",
      soak_time,
      ",'",
      mean_time,
      "')"
    )
  )
  tow_id=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM TOWS WHERE VESSEL_ID = ",
      vessel_id,
      " AND MEAN_TIME = '",
      mean_time,
      "'"
    )
  )$TOW_ID
  dbGetQuery(
    conn=conn,
    statement=paste0(
      "INSERT INTO `TOWS_SUMMARY`(`TOW_ID`,`TS_MEAN_VALUE`,`TS_RANGE_VALUE`,`TS_STD_VALUE`,`TS_PARAMETER`,`TS_UOM`,`TS_SOURCE`) VALUES (",
      tow_id,
      ",",
      mean_temp,
      ",NULL,",
      std_temp,
      ",'TEMP','DEGREES CELSIUS','TELEMETRY'),(",
      tow_id,
      ",",
      mean_depth,
      ",",
      range_depth,
      ",NULL,'DEPTH','m','TELEMETRY')"
    )
  )
  ## Insert a record into the vessel_status table
  ## Collect the most recent status report
  mr=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM VESSEL_STATUS WHERE TIMESTAMP=(SELECT MAX(TIMESTAMP) FROM VESSEL_STATUS WHERE VESSEL_ID = ",
      vessel_id,
      " AND TIMESTAMP < '",
      transmit_time,
      "')"
    )
  )
  ## Calculate distance traveled
  distance=ifelse(
    nrow(mr)==0||is.null(mr$LATITUDE)||is.null(mr$LONGITUDE),
    "NULL",
    distHaversine(
      c(lon,lat),
      c(mr$LONGITUDE,mr$LATITUDE)
    )/1000
  )
  dbGetQuery(
    conn=mydb,
    statement=paste0(
      "INSERT INTO `VESSEL_STATUS`(`VESSEL_ID`,`REPORT_TYPE`,`LATITUDE`,`LONGITUDE`,`TIMESTAMP`,`DISTANCE_TRAVELED`) VALUES (",
      vessel_id,
      ",'SUMMARY_DATA',",
      lat,
      ",",
      lon,
      ",'",
      ymd_hms(transmit_time),
      "',",
      distance,
      ")"
    )
  )
  status_id=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM VESSEL_STATUS WHERE VESSEL_ID = ",
      vessel_id,
      " AND TIMESTAMP = '",
      transmit_time,
      "'"
    )
  )
  response=list(
    "STATUS"= "The following records were inserted",
    "TOW RECORD"=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM odn_data WHERE TOW_ID = ",
        tow_id
      )
    ),
    "VESSEL STATUS RECORD"=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM VESSEL_STATUS WHERE REPORT_ID = ",
        status_id
      )
    )
  )
  message(response)
  dbDisconnectAll()
  return(response)
}

#* Record status updates and haul average data transmissions via satellite (old style, fixed gear only)
#* @param data A string of hex data from a ROCKBLOCK
#* @param serial The serial number of the ROCKBLOCK
#* @param imei The satellite transmitter's International Mobile Equipment Identity
#* @param transmit_time time of transmission in UTC
#* @post /getRock_API_old_fixed
function(data,serial,imei,transmit_time){
  ## Print startup message to log
  message(
    paste0(
      "Processing old format fixed gear transmission at ",
      Sys.time(),
      "\nData = ",
      data
    )
  )
  ## Connect to database
  mydb = dbConnector(db_config)
  ## Identify vessel using satellite transmitter information
  vessel_id=vesselSatLookup(imei,serial,mydb)
  ## Decode the data
  ## Convert the data from hex to character
  datastring=rawToChar(
    as.raw(
      strtoi(
        wkb::hex2raw(data),
        16L
      )
    )
  )
  message(
    paste0(
      "data = '",
      data,
      "'"
    )
  )
  ## Check to see if the data is a status report or actual fishing
  if(strsplit(
    x=datastring,
    split=","
  )[[1]][3]=="0000000000"){
    message("Status report, not fishing data, no record inserted in TOWS")
    ## Extract latitude
    raw=strsplit(
      x=datastring,
      split=","
    )[[1]][1]
    lat=as.numeric(substr(raw,1,2))+as.numeric(substr(raw,3,nchar(raw)))/60
    raw=strsplit(
      x=datastring,
      split=","
    )[[1]][2]
    lon=(as.numeric(substr(raw,1,2))+as.numeric(substr(raw,3,nchar(raw)))/60)*-1
    ## Collect the most recent status report
    mr=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM VESSEL_STATUS WHERE TIMESTAMP=(SELECT MAX(TIMESTAMP) FROM VESSEL_STATUS WHERE VESSEL_ID = ",
        vessel_id,
        " AND TIMESTAMP < '",
        transmit_time,
        "')"
      )
    )
    ## Calculate distance traveled
    distance=ifelse(
      nrow(mr)==0||is.null(mr$LATITUDE)||is.null(mr$LONGITUDE),
      "NULL",
      distHaversine(
        c(lon,lat),
        c(mr$LONGITUDE,mr$LATITUDE)
      )/1000
    )
    ## Insert a record into the vessel_status table
    dbGetQuery(
      conn=mydb,
      statement=paste0(
        "INSERT INTO `VESSEL_STATUS`(`VESSEL_ID`,`REPORT_TYPE`,`LATITUDE`,`LONGITUDE`,`TIMESTAMP`,`DISTANCE_TRAVELED`) VALUES (",
        vessel_id,
        ",'SHORT_STATUS',",
        lat,
        ",",
        lon,
        ",'",
        ymd_hms(transmit_time),
        "',",
        distance,
        ")"
      )
    )
    newrecord=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM VESSEL_STATUS WHERE VESSEL_ID = ",
        vessel_id,
        " AND TIMESTAMP = '",
        ymd_hms(transmit_time),
        "'"
      )
    )
    message(toJSON(newrecord))
    dbDisconnectAll()
    return(
      list(
        "STATUS"="Status record added",
        "RECORD"=newrecord
        )
    )
  }
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
  ## Extract the last 4 of the MAC address and use that to look up vessel id
  mac4=paste0(
    toupper(substr(raw[[1]][2],1,2)),
    ":",
    toupper(substr(raw[[1]][2],3,4))
  )
  ## Mean time is the temporal midpoint of the haul and is estimated as the transmission time - the soak time / 2
  mean_time=ymd_hms(transmit_time)-minutes(round(soak_time/2,0))
  ## Check to see if the record already exists
  record=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM TOWS WHERE VESSEL_ID = ",
      vessel_id,
      " AND MEAN_LATITUDE = ",
      round(lat,5),
      " AND MEAN_LONGITUDE = ",
      round(lon,5),
      " AND SOAK_TIME = ",
      soak_time,
      " AND MEAN_TIME = '",
      mean_time,
      "'"
    )
  )
  if(nrow(record)!=0){
    message("Record already exists, no new record added")
    dbDisconnectAll()
    return("Record already exists, no new record added")
  }
  ## If the record doesn't already exist, create an insert statement to load the data
  ## Create the INSERT statement to load the data
  conn=dbConnector(db_config2)
  dbGetQuery(
    conn=conn,
    statement=paste0(
      "INSERT INTO `TOWS`(`VESSEL_ID`,`MEAN_LATITUDE`,`MEAN_LONGITUDE`,`SOAK_TIME`,`MEAN_TIME`) VALUES (",
      vessel_id,
      ",",
      lat,
      ",",
      lon,
      ",",
      soak_time,
      ",'",
      mean_time,
      "')"
    )
  )
  tow_id=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM TOWS WHERE VESSEL_ID = ",
      vessel_id,
      " AND MEAN_TIME = '",
      mean_time,
      "'"
    )
  )$TOW_ID
  dbGetQuery(
    conn=conn,
    statement=paste0(
      "INSERT INTO `TOWS_SUMMARY`(`TOW_ID`,`TS_MEAN_VALUE`,`TS_RANGE_VALUE`,`TS_STD_VALUE`,`TS_PARAMETER`,`TS_UOM`,`TS_SOURCE`) VALUES (",
      tow_id,
      ",",
      mean_temp,
      ",NULL,",
      std_temp,
      ",'TEMP','DEGREES CELSIUS','TELEMETRY'),(",
      tow_id,
      ",",
      mean_depth,
      ",",
      range_depth,
      ",NULL,'DEPTH','m','TELEMETRY')"
    )
  )
  ## Insert a record into the vessel_status table
  ## Collect the most recent status report
  mr=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM VESSEL_STATUS WHERE TIMESTAMP=(SELECT MAX(TIMESTAMP) FROM VESSEL_STATUS WHERE VESSEL_ID = ",
      vessel_id,
      " AND TIMESTAMP < '",
      transmit_time,
      "')"
    )
  )
  ## Calculate distance traveled
  distance=ifelse(
    nrow(mr)==0||is.null(mr$LATITUDE)||is.null(mr$LONGITUDE),
    "NULL",
    distHaversine(
      c(lon,lat),
      c(mr$LONGITUDE,mr$LATITUDE)
    )/1000
  )
  dbGetQuery(
    conn=mydb,
    statement=paste0(
      "INSERT INTO `VESSEL_STATUS`(`VESSEL_ID`,`REPORT_TYPE`,`LATITUDE`,`LONGITUDE`,`TIMESTAMP`,`DISTANCE_TRAVELED`) VALUES (",
      vessel_id,
      ",'SUMMARY_DATA',",
      lat,
      ",",
      lon,
      ",'",
      ymd_hms(transmit_time),
      "',",
      distance,
      ")"
    )
  )
  status_id=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM VESSEL_STATUS WHERE VESSEL_ID = ",
      vessel_id,
      " AND TIMESTAMP = '",
      transmit_time,
      "'"
    )
  )
  ## Create a response
  response=list(
    "STATUS"= "The following records were inserted",
    "TOW RECORD"=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM odn_data WHERE TOW_ID = ",
        tow_id
      )
    ),
    "VESSEL STATUS RECORD"=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT * FROM VESSEL_STATUS WHERE REPORT_ID = ",
        status_id
      )
    )
  )
  message(response)
  ## Close all database connections and return the response
  dbDisconnectAll()
  return(response)
}


