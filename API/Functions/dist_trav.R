## Select most recent status report from database and calculate distance traveled
## Collect the most recent status report
library(geosphere)
distTrav=function(vessel_id,transmit_time,dbconn,lon,lat){
  ## Locate the most recent record
  mr=dbGetQuery(
    conn=dbconn,
    statement=paste0(
      "SELECT * FROM VESSEL_STATUS WHERE TIMESTAMP = (SELECT MAX(TIMESTAMP) FROM VESSEL_STATUS WHERE VESSEL_ID = ",
      vessel_id,
      " AND TIMESTAMP < '",
      transmit_time,
      "')"
    )
  )
  ## Validate the record and calculate the Haversine distance (km) if possible
  distance=ifelse(
    nrow(mr)==0||is.null(mr$LATITUDE)||is.null(mr$LONGITUDE),
    "NULL",
    distHaversine(
      c(lon,lat),
      c(mr$LONGITUDE,mr$LATITUDE)
    )/1000
  )
  distance=round(distance,2)
  ## Return the distance
  return(distance)
}