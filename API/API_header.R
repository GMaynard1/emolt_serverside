## ---------------------------
## Script name: API_header.R
##
## Purpose of script: contains code to load all libraries and external
##    functions necessary for the eMOLT API to function.
##    This file should be stored at the same directory level as
##    plumber.R, which means the following location on the eMOLT
##    server:
##
##    - /etc/plumber/API_header.R
##
##    and the following location on development computers:
##
##    - ~gitHubRepositories/emolt_serverside/API/API_header.R
##
## Date Created: 2022-08-24
##
## Software code created by U.S. Government employees is
## not subject to copyright in the United States
## (17 U.S.C. §105).
##
## Email: george.maynard@noaa.gov
##
## ---------------------------
## Notes:
##
##  - 2022-08-24: Previously, this information was contained on lines
##      2-62 (approximately) of the API code
##  - 2022-09-28: Added new functions to pull raw data from the database for use
##      in the ODN portal. Still need to implement authentication before serving
##      data from other vessels (beyond F/V Lisa Ann III)
##  - 2022-10-14: Added API Key requirement for access from the ODN Portal
##
## ---------------------------

## Load necessary libraries
require(aws.s3)
require(config)
require(geosphere)
require(jose)
require(jsonlite)
require(lubridate)
require(openair)
require(plumber)
require(readr)
require(reticulate)
require(RMySQL)
require(stringr)
require(wkb)

## Ensure enough database connections are available for multiple vessels
## reporting simultaneously
MySQL(max.con=50)

## Create a vector of functions to read in
functions=c(
  'check_transmission_type.R',
  'comms_dat.R',
  'create_py_dict.R',
  'db_connector.R',
  'db_disconnect_all.R',
  'dist_trav.R',
  #'file_save.R',
  'log_message.R',
  'logger_dat.R',
  'new_proc_short_status.R',
  'new_proc_summary_data.R',
  'old_fixed_proc_short_status.R',
  'old_fixed_proc_summary_data.R',
  'old_mobile_proc_short_status.R',
  'old_mobile_proc_summary_data.R',
  #'s3_filetype.R',
  'standard_mac.R',
  'vessel_dat.R',
  'vessel_name.R',
  'vessel_sat_lookup.R'
)

## Read in functions and database configuration values
if(Sys.info()[["nodename"]]%in%c("emoltdev","eMOLT")){
  ## Configuration values
  db_config=config::get(file="/etc/plumber/config.yml")$dev_local
  db_config2=config::get(file="/etc/plumber/config.yml")$add_local_dev
  db_config3=config::get(file="/etc/plumber/config.yml")$add_dev_intranet
  aws_config=config::get(file="/etc/plumber/config.yml")$aws_bucket
  odn_key=read_jwk("/etc/plumber/Keys/odn_key.json")
  ## Functions
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
  aws_config=config::get(file="C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/config.yml")$aws_bucket
  odn_key=read_jwk("C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/Keys/odn_key.json")
  for(i in 1:length(functions)){
    source(
      paste0(
        "C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/API/Functions/",
        functions[i]
      )
    )
  }
}
