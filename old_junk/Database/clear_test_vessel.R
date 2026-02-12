source("API/API_header.R")

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
