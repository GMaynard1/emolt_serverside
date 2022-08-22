checkTransmissionType=function(data){
  if(nchar(data)<65){
    return("SHORT_STATUS")
  } else {
    return("SUMMARY_DATA")
  }
}