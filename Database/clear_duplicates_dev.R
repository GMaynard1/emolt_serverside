source("API/API_header.R")
mydb=dbConnector(db_config2)

## ----------
## Find duplicates in the VESSEL_STATUS table
## Download all records from VESSEL STATUS
x=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM VESSEL_STATUS"
  )

## Find duplicates, skipping the report_id and timestamp columns
x$dup=duplicated(x[,-c(1,6)])
y=subset(x,x$dup==TRUE)

## Delete duplicate records
dbGetQuery(
  conn=mydb,
  statement=paste0(
    "DELETE FROM VESSEL_STATUS WHERE REPORT_ID IN (",
    paste0(
      y$REPORT_ID,
      collapse=","
      ),
    ")"
  )
)

## ----------
## Find duplicates in the TOWS_SUMMARY table
## Download all records from TOWS_SUMMARY
x=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM TOWS_SUMMARY"
)

## Find duplicates, skipping the report_id and timestamp columns
x$dup=duplicated(x[,-1])
y=subset(x,x$dup==TRUE)

## Delete duplicate records
dbGetQuery(
  conn=mydb,
  statement=paste0(
    "DELETE FROM TOWS_SUMMARY WHERE TS_ID IN (",
    paste0(
      y$TS_ID,
      collapse=","
    ),
    ")"
  )
)

## ----------
## Find duplicates in the TOWS table
## Download all records from TOWS
x=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM TOWS"
)

## Find duplicates, skipping the report_id and timestamp columns
x$MEAN_TIME=floor_date(ymd_hms(x$MEAN_TIME),unit="minutes")
x$dup=duplicated(x[,-1])
y=subset(x,x$dup==TRUE)

## Delete associated records from the TOW_SENSORS table
a=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM TOW_SENSORS"
)
b=subset(a,a$TOW_ID%in%y$TOW_ID)
dbGetQuery(
  conn=mydb,
  statement=paste0(
    "DELETE FROM TOW_SENSORS WHERE TOW_SENSOR_ID IN (",
    paste0(
      b$TOW_SENSOR_ID,
      collapse=","
    ),
    ")"
  )
)

## Delete associated records from the TOWS_RAW table
a=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM TOWS_RAW"
)
b=subset(a,a$TOW_ID%in%y$TOW_ID)
dbGetQuery(
  conn=mydb,
  statement=paste0(
    "DELETE FROM TOWS_RAW WHERE TOWS_RAW_ID IN (",
    paste0(
      b$TOWS_RAW_ID,
      collapse=","
    ),
    ")"
  )
)
## Delete associated records from the TOWS_SUMMARY table
a=dbGetQuery(
  conn=mydb,
  statement="SELECT * FROM TOWS_SUMMARY"
)
b=subset(a, a$TOW_ID%in%y$TOW_ID)
dbGetQuery(
  conn=mydb,
  statement=paste0(
    "DELETE FROM TOWS_SUMMARY WHERE TS_ID IN (",
    paste0(
      b$TS_ID,
      collapse=","
    ),
    ")"
  )
)
## Delete duplicate records
dbGetQuery(
  conn=mydb,
  statement=paste0(
    "DELETE FROM TOWS WHERE TOW_ID IN (",
    paste0(
      y$TOW_ID,
      collapse=","
    ),
    ")"
  )
)
