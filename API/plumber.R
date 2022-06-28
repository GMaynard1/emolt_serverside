# plumber.R
require(jsonlite)
require(plumber)
require(reticulate)
require(RMySQL)
require(wkb)

## Read in configuration values
db_config=config::get(file="API/config.yml")$dev_remote

#* @apiTitle eMOLT dev API
#* @apiDescription This is the development API for the eMOLT project.
#* @apiContact list(name="API Support",email="george.maynard@noaa.gov") 



#* Get MAC addresses associated with vessels
#* @param vessel The vessel of interest
#* @get /readMAC
function(vessel="ALL"){
  ## Connect to database
  mydb=dbConnect(
    MySQL(), 
    user=db_config$username, 
    password=db_config$password, 
    dbname=db_config$db, 
    host=db_config$host,
    port=db_config$port
    )
  data=dbGetQuery(
    conn=mydb,
    statement="SELECT * FROM vessel_mac"
  )
  if(vessel=="ALL"){
    print(data)
  } else {
    print(subset(data,data$VESSEL_NAME==toupper(vessel)))
  }
}

#* Create and export control file during vessel setup
#* @param vessel The vessel you'd like to create a control file for
#* @serializer unboxedJSON
#* @get /getControl_File
function(vessel){
  ## Connect to database
  mydb=dbConnect(
    MySQL(), 
    user=db_config$username, 
    password=db_config$password, 
    dbname=db_config$db, 
    host=db_config$host,
    port=db_config$port
  )
  
  ## Standardize the vessel name to all uppercase, no underscore, remove the 
  ## leading characters F/V if they exist
  vessel=gsub(
      pattern="F/V",
      replacement="",
      x=gsub(
        pattern="_",
        replacement=" ",
        x=toupper(vessel)
      )
    )
  ## Query the logger metadata out of the database
  loggerdat=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT * FROM vessel_mac WHERE VESSEL_NAME = '",
      vessel,
      "' AND EQUIPMENT_TYPE = 'LOGGER'"
    )
  )
  ## Query the gear type out of the database
  gear=dbGetQuery(
    conn=mydb,
    statement=paste0(
      "SELECT FMCODE FROM VESSELS INNER JOIN GEAR_CODES ON VESSELS.PRIMARY_GEAR = GEAR_CODES.GEAR_CODE WHERE VESSEL_NAME = '",
      vessel,
      "'"
    )
  )$FMCODE
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
  metadata=data.frame(
    "time_range"=1,
    "Fathom"=.1,
    "transmitter"='yes',
    "mac_addr"=loggerdat$HARDWARE_ADDRESS,
    "gear_type"=gear,
    "vessel_num"=loggerdat$EMOLT_NUM,
    "vessel_name"=vessel,
    "tilt"='no'
  )
  parameters=data.frame(
    "path"="/home/pi/rtd_global/",
    "sensor_type"=loggerdat$MAKE,
    "time_diff_nke"=0,
    "tem_unit"="Fahrenheit",
    "depth_unit"="Fathoms",
    "local_time"=-4
  )
  # py_run_string("import json")
  # ## Create the metadata dictionary
  # py_run_string(
  #   paste0(
  #     "metadata = {'time_range': 1,'Fathom': .1,'transmitter': 'yes','mac_addr': '",
  #       loggerdat$HARDWARE_ADDRESS,
  #       "','moana_SN':'",
  #       loggerdat$SERIAL_NUMBER,
  #       "','gear_type': '",
  #       gear,
  #       "','vessel_num': ",
  #       loggerdat$EMOLT_NUM,
  #       ", 'vessel_name': '",
  #       vessel,
  #       "','tilt': 'no'}"
  #     )
  #   )
  # py_run_string("with open('metadata.json','w') as fp: json.dump(metadata,fp)")
  # ## Create the parameters dictionary
  # py_run_string(
  #   paste0(
  #     "parameters = {'path': '/home/pi/rtd_global/', 'sensor_type': ['",
  #     loggerdat$MAKE,
  #     "'], 'time_diff_nke': 0, 'tem_unit': 'Fahrenheit', 'depth_unit': 'Fathoms', 'local_time': -4 }"
  #   )
  # )
  # py_run_string("with open('parameters.json','w') as fp: json.dump(parameters,fp)")

  list("metadata"=metadata,"parameters"=parameters)

}
#* Record status updates and haul average data transmissions via satellite
#* @param datastring The payload from a Rockblock
#* @post /getRock_API
function(datastring){
  print("tbd")
}