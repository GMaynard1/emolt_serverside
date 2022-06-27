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
  py_run_string("import json")
  py_run_string("metadata = {'time_range': 1,
            'Fathom': .1,
            'transmitter': 'yes',
            'mac_addr': ['CF:D4:F1:9D:8D:A8','ED:E8:8C:F6:86:C6','C1:07:7B:6E:C6:16'],
            'moana_SN': '0113',
            'gear_type': 'mobile',
            'vessel_num': 99,
            'vessel_name': 'Default_setup',
            'tilt': 'no'}")
  py_run_string("with open('dict.json','w') as fp: json.dump(metadata,fp)")
  read_json("dict.json",simplifyVector = TRUE)
}
#* Record status updates and haul average data transmissions via satellite
#* @param datastring The payload from a Rockblock
#* @post /getRock_API
function(datastring){
  print("tbd")
}