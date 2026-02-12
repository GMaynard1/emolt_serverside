## ---------------------------
## Script name: Shiny_header.R
##
## Purpose of script: contains code to load all libraries and external
##    functions necessary for eMOLT shiny apps to function.
##    This file should be stored at...
##    which means the following location on the server
##
##    - 
##
##    and the following location on development computers:
##
##    - 
##
## Date Created: 2022-12-14
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
##
## ---------------------------
## Load necessary libraries
require(config)
require(devtools)
require(dplyr)
require(geosphere)
require(jose)
require(jsonlite)
require(lubridate)
require(magrittr)
require(openair)
require(plumber)
require(readr)
require(reticulate)
require(RMySQL)
require(shiny)
require(shinyalert)
require(shinyTime)
require(stringr)
require(tidyr)
require(wkb)

## Create a vector of functions to read in
functions=c(
  'db_connector.R',
  'db_disconnect_all.R'
)

## Read in configuration values
db_config=config::get(file="C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/WebGUI/config.yml")$add_remote_dev

for(i in 1:length(functions)){
  source(
    paste0(
      "C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/WebGUI/Functions/",
      functions[i]
    )
  )
}






