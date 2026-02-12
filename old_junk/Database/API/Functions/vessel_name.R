## Standardize vessel name
vessel_name=function(vessel){
  ## Standardize the vessel name to all uppercase, no underscore, remove the 
  ## leading characters F/V if they exist
  VESSEL=gsub(
    pattern="F/V",
    replacement="",
    x=gsub(
      pattern="_",
      replacement=" ",
      x=toupper(vessel)
    )
  )
  return(VESSEL)
}