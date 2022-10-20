# plumber.R

## Load the header file
source("API_header.R")

#* @apiTitle eMOLT dev API
#* @apiDescription This is the development API for the eMOLT project.
#* @apiContact list(name="API Support",email="george.maynard@noaa.gov") 
#* @apiVersion 1.1.1

#* Authenticate for access from the ODN portal
#* @filter ODN_Auth
function(req){
  ## If the request is for an unsecured endpoint, just pass it through
  if(req$PATH_INFO!="/get_odn_data"){
    plumber::forward()
  } else {
    ## Otherwise, read in the key and attempt to authenticate
    odn_pubkey=as.list(odn_key)$pubkey
    d_claim=jwt_decode_sig(req$HTTP_APIKEY,odn_pubkey)
    plumber::forward()
  }
}

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
  
  ## Create a read-write database connection
  conn = dbConnector(db_config)
  
  ## Convert transmission time to POSIX format
  transmit_time = ymd_hms(transmit_time)
  
  transmit_time = floor_date(
    transmit_time,
    unit="minutes"
  )
  
  ## Identify the vessel using information from the satellite transmitter
  vessel_id = vesselSatLookup(imei,serial,conn)
  
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
}

#* Record status updates and haul average data transmissions via satellite (old style, mobile gear only)
#* @param data A string of hex data from a ROCKBLOCK
#* @param serial The serial number of the ROCKBLOCK
#* @param imei The satellite transmitter's International Mobile Equipment Identity
#* @param transmit_time time of transmission in UTC
#* @post /getRock_API_old_mobile
function(data,serial,imei,transmit_time){
  ## Print startup message to log
  logMessage("Processing old mobile satellite transmission",data)
  
  ## Connect to database
  conn = dbConnector(db_config)
  
  ## Identify the vessel
  vessel_id=vesselSatLookup(imei,serial,conn)
  
  ## Convert transmission time to POSIX format
  transmit_time = floor_date(ymd_hms(transmit_time),unit="minutes")
  
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
  
  if(datType=="SHORT_STATUS"){
    oldMobile_procShortStatus(datastring,conn,vessel_id,transmit_time)
  } else {
    if(datType=="SUMMARY_DATA"){
      old_mobile_proc_summary_data(datastring,conn,vessel_id,transmit_time)
    }
  }
}

#* Record status updates and haul average data transmissions via satellite (old style, fixed gear only)
#* @param data A string of hex data from a ROCKBLOCK
#* @param serial The serial number of the ROCKBLOCK
#* @param imei The satellite transmitter's International Mobile Equipment Identity
#* @param transmit_time time of transmission in UTC
#* @post /getRock_API_old_fixed
function(data,serial,imei,transmit_time){
  ## Print startup message to log
  logMessage("Processing old fixed satellite transmission",data)
  
  ## Clear all existing connections
  dbDisconnectAll()
  
  ## Connect to database
  mydb = dbConnector(db_config)
  conn = dbConnector(db_config2)
  
  ## Identify the vessel
  vessel_id=vesselSatLookup(imei,serial,mydb)
  
  ## Convert transmission time to POSIX format
  transmit_time = floor_date(ymd_hms(transmit_time),unit="minutes")
  
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
  
  if(datType=="SHORT_STATUS"){
    old_fixed_proc_short_status(datastring,conn,vessel_id,transmit_time)
  } else {
    if(datType=="SUMMARY_DATA"){
      old_fixed_proc_summary_data(datastring,conn,vessel_id,transmit_time)
    }
  }
}

# #* Load data from the Lowell S3 bucket
# #* @param date A datetime value describing when the load was initiated
# #* @param filename The name of the file to be loaded
# #* @param contents The contents of the file
# #* @param newfilename The modified version of the filename that replaces "/" with "_"
# #* @param last_modified The last time the file was modified in the AWS S3 Bucket
# #* @post /dev_S3_load
# function(date,filename,newfilename,contents,last_modified){
#   
#   ## Print a startup message to the log
#   logMessage("Processing S3 file ", filename)
#   
#   ## Connect to database
#   conn=dbConnector(db_config2)
#   
#   ## Identify the filetype
#   filetype=s3_filetype(newfilename)
#   
#   logMessage("Filetype is: ", filetype)
#   ## If the filetype is unknown, return an error. Otherwise, process the file 
#   if(filetype=="UNKNOWN"){
#     dbDisconnect(conn)
#     return(
#       list(
#         "STATUS" = "UNKNOWN FILETYPE",
#         "VALUES" = "ERROR"
#         )
#     )
#   } else {
#     file_save(filename,newfilename,contents,conn,date,last_modified)
#   }
# }

#* Grab the minimum and maximum dates of data available for a particular vessel
#* @param vessel_id The vessel_id from the eMOLT database for the vessel of interest
#* @get /get_odn_dates
function(vessel_id){
  ## Connect to the database
  conn=dbConnector(db_config)
  
  ## Grab the minimum date
  minDate=dbGetQuery(
    conn=conn,
    statement=paste0(
      "SELECT X.MIN_DATE FROM (SELECT VESSEL_ID,MIN(TIMESTAMP) AS MIN_DATE FROM odn_data_raw GROUP BY VESSEL_ID) X WHERE X.VESSEL_ID = ",
      vessel_id
    )
  )$MIN_DATE
  
  ## Grab the maximum date
  maxDate=dbGetQuery(
    conn=conn,
    statement=paste0(
      "SELECT X.MAX_DATE FROM (SELECT VESSEL_ID,MAX(TIMESTAMP) AS MAX_DATE FROM odn_data_raw GROUP BY VESSEL_ID) X WHERE X.VESSEL_ID = ",
      vessel_id
    )
  )$MAX_DATE
  
  ## Disconnect from the database
  dbDisconnect(conn)
  
  ## Return minDate and maxDate
  return(
    list(
      "min_date"=minDate,
      "max_date"=maxDate
    )
  )
}
#* Make high resolution data for a particular user available to the ODN portal
#* @param vessel_id The vessel_id from the eMOLT database for the vessel of interest
#* @param start_date beginning date of requested data
#* @param end_date end date of requested data
#* @get /get_odn_data
function(vessel_id,start_date,end_date){
  ## Connect to the database
  conn=dbConnector(db_config)
  
  ## Grab the raw data from the database
  raw_data=dbGetQuery(
    conn=conn,
    statement=paste0(
      "SELECT * FROM odn_data_raw WHERE VESSEL_ID = ",
      vessel_id,
      " AND TIMESTAMP BETWEEN '",
      start_date,
      "' AND '",
      end_date,
      "'"
    )
  )
  
  ## Grab the haul average data from the database
  haul_avg_data=dbGetQuery(
    conn=conn,
    statement=paste0(
      "SELECT * FROM odn_data WHERE VESSEL_ID = ",
      vessel_id,
      " AND MEAN_TIME BETWEEN '",
      start_date,
      "' AND '",
      end_date,
      "'"
    )
  )
  
  ## Apply the QAQC routine to the raw data (haul average data should 
  ## already be QAQC'd)
  #THIS IS JUST A PLACEHOLDER FOR NOW
  
  ## Return the values
  return(
    list(
      "VESSEL_ID"=vessel_id,
      "RAW_DATA"=raw_data,
      "HAUL_AVG_DATA"=haul_avg_data
    )
  )
}
