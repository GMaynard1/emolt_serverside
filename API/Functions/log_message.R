logMessage=function(messageText,data){
  message(
    paste0(
      "\n----------\n",
      messageText,
      "\nTime: ",
      Sys.time(),
      "\nData: ",
      data,
      "\n----------\n"
    )
  )
}