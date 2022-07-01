# plumber.R
## Load necessary libraries
require(config)
require(jsonlite)
require(plumber)
require(readr)
require(reticulate)
require(RMySQL)
require(wkb)

## Read in functions and database configuration values
if(Sys.info()[["nodename"]]=="emoltdev"){
  setwd("/etc/plumber/")
  db_config=config::get(file="config.yml")$dev_local
} else {
  setwd("C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/")
  db_config=config::get(file="config.yml")$dev_remote
}

source("Functions/create_py_dict.R")
source("Functions/dbConnector.R")
source("Functions/loggerdat.R")
source("Functions/vessel_name.R")
source("Functions/vesseldat.R")

#* @apiTitle eMOLT dev API
#* @apiDescription This is the development API for the eMOLT project.
#* @apiContact list(name="API Support",email="george.maynard@noaa.gov") 



#* Get logger MAC addresses associated with vessels
#* @param vessel The vessel of interest
#* @get /readMAC
function(vessel="ALL"){
  ## Connect to database
  mydb=dbConnector(db_config)
  
  ## Standardize vessel name
  vessel=vessel_name(vessel)
  
  ## Download and display data
  loggerdat(vessel)
}

#* Create and export control file for Lowell logger system during vessel setup
#* @param vessel The vessel you'd like to create a control file for
#* @serializer cat
#* @get /getControl_File_Lowell
function(vessel){
  ## Connect to database
  mydb=dbConnector(db_config)
  
  ## Standardize the vessel name
  vessel=vessel_name(vessel)
  
  ## Query the logger metadata out of the database
  loggerdat=loggerdat(vessel)
  
  ## Query the transmitter metadata out of the database
  transdat=transdat(vessel)
}
#* Create and export control file for Moana logger system during vessel setup
#* @param vessel The vessel you'd like to create a control file for
#* @serializer cat
#* @get /getControl_File
function(vessel){
  ## Connect to database
  mydb=dbConnector(db_config)
  
  ## Standardize the vessel name to all uppercase, no underscore, remove the 
  ## leading characters F/V if they exist
  vessel=vessel_name(vessel)
  
  ## Query the logger metadata out of the database
  loggerdat=loggerdat(vessel)
  
  ## Query the gear type out of the database
  gear=vesseldat(vessel)$FMCode
  
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
  ## Return the text as a file to the end user
  as_attachment(y,"setup_rtd.py")
}
#* Record status updates and haul average data transmissions via satellite
#* @param datastring The payload from a Rockblock
#* @post /getRock_API
function(datastring){
  print("tbd")
}
