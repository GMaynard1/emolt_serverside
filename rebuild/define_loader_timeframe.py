from datetime import datetime, timedelta

def get_loader_timeframe(days=0,hours=0):
  """
  Returns two strings in YYYY-MM-DD hh:mm:ss format
  'end_time' = now
  'start_time' = now - (days+hours)
  """
  
  end_time = datetime.now()
  
  start_time = end_time - timedelta(days=days, hours=hours)
  
  format_str = "%Y-%m-%d %H:%M:%S"
  
  return(start_time.strftime(format_str),end_time.strftime(format_str))
