## Standardize MAC address
require(tidyverse)
standard_mac=function(mac){
  MAC=toupper(ifelse(
    nchar(mac)==17,
    gsub(
      "[[:punct:]]",":",mac
    ),
    paste0(substring(
      text=mac,
      first=(seq(1,nchar(mac),2)),
      last=(seq(2,nchar(mac),2))
    ),
    collapse=":")
  ))
  if(str_detect(MAC,"^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})|([0-9a-fA-F]{4}\\.[0-9a-fA-F]{4}\\.[0-9a-fA-F]{4})$")==FALSE){
    return("ERROR")
  } else {
    return(MAC)
  }
}
