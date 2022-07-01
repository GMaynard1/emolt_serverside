# plumber.R
## Load necessary libraries
require(config)
require(jsonlite)
require(plumber)
require(readr)
require(reticulate)
require(RMySQL)
require(wkb)

## Vector of functions to read in
functions=c(
  'commsdat.R',
  'create_py_dict.R',
  'dbConnector.R',
  'loggerdat.R',
  'vessel_name.R',
  'vesseldat.R'
)
## Read in functions and database configuration values
if(Sys.info()[["nodename"]]=="emoltdev"){
  db_config=config::get(file="/etc/plumber/config.yml")$dev_local
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



#* Get logger MAC addresses associated with vessels
#* @param vessel The vessel of interest
#* @get /readMAC
function(vessel="ALL"){
  ## Connect to database
  mydb=dbConnector(db_config)
  
  ## Standardize vessel name
  vessel=vessel_name(vessel)
  
  ## Download and display data
  loggerdat(vessel,mydb)
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
    paste0(5,"\t# logger time range(minutes), set it to 5 , during the test. Set it to the shortest haul time. Unit Minute"),
    paste0(0,"\t# Fathom, Set to 0 for test, set to 15 after the test"),
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
  ## Return the text as a file to the end user
  as_attachment(y,"control_file.txt")
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
  ## Return the text as a file to the end user
  as_attachment(y,"setup_rtd.py")
}
#* Record status updates and haul average data transmissions via satellite
#* @param datastring The payload from a Rockblock
#* @post /getRock_API
function(datastring){
  print("tbd")
}
