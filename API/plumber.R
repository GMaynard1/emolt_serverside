# plumber.R
require(plumber)
require(RMySQL)
source('login.R')

#* Get MAC addresses associated with vessels
#* @param vessel The vessel of interest
#* @get /readMAC
function(vessel="ALL"){
  ## Collect login info from file
  ## Connect to database
  mydb=dbConnect(
    MySQL(), 
    user=username, 
    password=password, 
    dbname=db, 
    host=host,
    port=port
    )
  data=dbGetQuery(
    conn=mydb,
    statement="SELECT * FROM VESSEL_MAC"
  )
  if(vessel=="ALL"){
    print(data)
  } else {
    print(subset(data,data$VESSEL_NAME==toupper(vessel)))
  }
}

#* Get SIM ICCIDs associated with vessels
#* @param vessel The vessel of interest
#* @get /readSIM
function(vessel="ALL"){
  ## Connect to database
  mydb=dbConnect(
    MySQL(), 
    user=username, 
    password=password, 
    dbname=db, 
    host=host,
    port=port
  )
  data=dbGetQuery(
    conn=mydb,
    statement="SELECT * FROM VESSEL_SIM"
  )
  if(vessel=="ALL"){
    print(data)
  } else {
    print(subset(data,data$VESSEL_NAME==toupper(vessel)))
  }
}

#* Insert a reboot record into the database
#* @param timestamp The time that the device rebooted
#* @param MAC The MAC address of the device
#* @param IP The IP address of the device
#* @post /insert_reboot
function(timestamp, MAC, IP){
  ## Read in the login credentials from a file
  user=username
  password=password
  dbname=db
  host=host
  port=port
  ## Connect to database
  mydb=dbConnect(
    MySQL(), 
    user=user, 
    password=password, 
    dbname=dbname, 
    host=host,
    port=port
  )
  ## Look up the MAC address
  temp=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM VESSEL_MAC WHERE HARDWARE_ADDRESS = '",
      MAC,
      "'"
    )
  )
  ## If the MAC address doesn't exist in the database, return an error
  if(nrow(temp)==0){
    stop("MAC address not found")
  } else {
    ## Otherwise, form an insert statement using the correct hardware ID
    hid=dbGetQuery(
      conn=mydb,
      statement=paste0(
        "SELECT HARDWARE_ID FROM HARDWARE_ADDRESSES WHERE ADDRESS_TYPE = 'MAC' AND HARDWARE_ADDRESS = '",
        MAC,
        "'"
      )
    )[1,1]
    statement=paste0(
      "INSERT INTO TELEMETRY_STATUS (`TS_REPORT_ID`,`TS_LATITUDE`,`TS_LONGITUDE`,`TS_REPORT_DATE`,`TR_AMT_MB`,`HARDWARE_ID`,`IP_ADDRESS`) VALUES (0,NULL,NULL,'",
      timestamp,
      "',NULL,",
      hid,
      ",'",
      IP,
      "')"
    )
    ## Execute the statement
    dbGetQuery(
      conn=mydb,
      statement=statement
    )
  }
}

#* Record status updates and haul average data transmissions via satellite
#* @param imei The IMEI number of the device
#* @param device_type The type of device
#* @param serial Serial number of the device
#* @param momsn Number of messages sent from the device
#* @param transmit_time Timestamp of message transmission
#* @param data Information sent in the report whether a status update or data upload
#* @post /getRock_API
function(imei, device_type, serial, momsn, data){
  print(imei)
  print(device_type)
  print(serial)
  print(momsn)
  print(transmit_time)
  print(data)
}