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
  'commsdat.R',
  'create_py_dict.R',
  'dbConnector.R',
  'dbDisconnectAll.R',
  'loggerdat.R',
  'standard_mac.R',
  'vessel_name.R',
  'vesseldat.R',
  'vesselSatLookup.R'
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
## Connect to the database
mydb=dbConnector(db_config2)
## Query tows associated with the test vessel
tow_ids=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM TOWS WHERE VESSEL_ID = 23"
)$TOW_ID

## Clear data from the tows_summary table
dbGetQuery(
  conn=mydb,
  statement=paste0("DELETE FROM TOWS_SUMMARY WHERE TOW_ID IN (",
    paste0(tow_ids,collapse=","),
    ")"
  )
)

## Clear data from the vessel_status table
dbGetQuery(
  conn=mydb,
  statement="DELETE FROM VESSEL_STATUS WHERE VESSEL_ID = 23"
)

## Clear data from the tows table
dbGetQuery(
  conn=mydb,
  statement="DELETE FROM TOWS WHERE VESSEL_ID = 23"
)
