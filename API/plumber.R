# plumber.R
require(config)
require(jsonlite)
require(plumber)
require(readr)
require(reticulate)
require(RMySQL)
require(wkb)

## Read in configuration values
db_config=config::get(file="config.yml")$dev_local

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
#* @serializer cat
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
  ## Create a filename based on the vessel name and date
  filename=paste0(
    "/etc/plumber/control_files/",
    vessel,
    "_",
    Sys.Date(),
    "_setup_rtd.py"
  )
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
  py_run_string(
    paste0(
      c("listA=(",
        paste0(
          keys,
          collapse=","
          ),
        ")"
        ),
      collapse=""
    )
  )
  py_run_string(
    paste0(
      c("listB=(",
        paste0(
          values,
          collapse=","
        ),
        ")"
      ),
      collapse=""
    )
  )
  py_run_string(
    "data=dict(zip(listA,listB))"
  )
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
  py_run_string(
    paste0(
      c("listA=(",
        paste0(
          keys,
          collapse=","
        ),
        ")"
      ),
      collapse=""
    )
  )
  py_run_string(
    paste0(
      c("listB=(",
        paste0(
          values,
          collapse=","
        ),
        ")"
      ),
      collapse=""
    )
  )
  py_run_string(
    "data=dict(zip(listA,listB))"
  )
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
  ## Return the text as a file to the end user
  as_attachment(y,"setup_rtd.py")
}
#* Record status updates and haul average data transmissions via satellite
#* @param datastring The payload from a Rockblock
#* @post /getRock_API
function(datastring){
  print("tbd")
}
