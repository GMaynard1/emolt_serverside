## Reads in a yaml database configuration and connects to a MySQL database
dbConnector = function(db_config){
  require(RMySQL)
  ## Connect to database
  mydb=dbConnect(
    MySQL(), 
    user=db_config$username, 
    password=db_config$password, 
    dbname=db_config$db, 
    host=db_config$host,
    port=db_config$port
  )
  return(mydb)
}