## Source the Web GUI Header
source("C:/Users/george.maynard/Documents/GitHubRepos/emolt_serverside/WebGUI/Shiny_header.R")

## Open a connection to the database
conn=dbConnector(db_config)

# Define UI
ui <- fluidPage(
  title="Add a new vessel visit",
  fluidRow(
    column(
      width = 6,
      selectInput(
        inputId='vessel_name',
        'Vessel Name:',
        choices=dbGetQuery(
          conn=conn,
          "SELECT VESSEL_NAME FROM VESSELS ORDER BY VESSEL_NAME"
        )$VESSEL_NAME
      ),
      selectInput(
        inputId='state',
        "State: ",
        choices=unique(
          dbGetQuery(
            conn=conn,
            "SELECT STATE_POSTAL FROM PORTS ORDER BY STATE_POSTAL"
          )$STATE_POSTAL
        )
      ),
      selectInput(
        inputId="port",
        label="Port: ",
        choices=dbGetQuery(
          conn=conn,
          paste0(
            "SELECT PORT_NAME FROM PORTS ORDER BY PORT_NAME"
          )
        )$PORT_NAME
      ),
      dateInput(
        inputId='vdate',
        label="Visit Date",
        format='yyyy-mm-dd'
      ),
      timeInput(
        inputId='vtime',
        label="Visit Time (local)",
        seconds=TRUE
      ),
      textAreaInput(
        inputId='notes',
        label="Visit Notes: ",
        value="",
        resize="both"
      ),
      actionButton(
        inputId="checkRecord",
        label="Check Record",
        icon('check')
      )
    )
  ),
  renderUI(
    textOutput('check')
  )
)

## Define server logic
server <- function(input, output) {
  ## Filter available ports by selected state
  observeEvent(
    input$state,{
      updateSelectInput(
        inputId="port",
        choices=dbGetQuery(
          conn=conn,
          paste0(
            "SELECT PORT_NAME FROM PORTS WHERE STATE_POSTAL = '",
            input$state,
            "' ORDER BY PORT_NAME"
          )
        )$PORT_NAME
      )
    }
  )
  ## Filter available equipment by equipment type and what is available both on 
  ## the vessel and in the inventory
  observeEvent(
    input$hwType,{
      vessel_id=dbGetQuery(
        conn=conn,
        statement=paste0(
          "SELECT VESSEL_ID FROM VESSELS WHERE VESSEL_NAME = '",
          input$vessel_name,
          "'"
        )
      )[1,1]
      captain=dbGetQuery(
        conn=conn,
        statement=paste0(
          "SELECT OPERATOR FROM VESSELS WHERE VESSEL_ID = ",
          vessel_id
        )
      )$OPERATOR[1]
      updateSelectInput(
        inputId="hwRemoved",
        choices=c("NA",
                  unite(
                    dbGetQuery(
                      conn=conn,
                      paste0(
                        "SELECT SERIAL_NUMBER, MAKE, MODEL FROM EQUIPMENT_INVENTORY WHERE EQUIPMENT_TYPE = '",
                        input$hwType,
                        "' AND CURRENT_LOCATION = 'VESSEL' AND CUSTODIAN = ",
                        captain,
                        " ORDER BY SERIAL_NUMBER"
                      )
                    ),
                    col="x",
                    remove=TRUE,
                    sep=" "
                  )$x
              )
        )
      updateSelectInput(
        inputId="hwInstalled",
        choices=c("NA",
                  unite(
                    dbGetQuery(
                      conn=conn,
                      paste0(
                        "SELECT SERIAL_NUMBER, MAKE, MODEL FROM EQUIPMENT_INVENTORY WHERE EQUIPMENT_TYPE = '",
                        input$hwType,
                        "' AND CURRENT_LOCATION NOT IN ('DECOMMISSIONED','LOST','VESSEL') ORDER BY SERIAL_NUMBER"
                      )
                    ),
                    col="x",
                    remove=TRUE,
                    sep=" "
                  )$x
        )
      )
    }
  )
  ## SAVE AND EXIT
  ## Produce a human-readable version of the equipment record to be inserted 
  ## into the database and ask the user for confirmation
  observeEvent(
    input$sae,{
      statement1=ifelse(
        input$hwRemoved=="NA",
        paste0(
          "No hardware was removed from the F/V ",
          input$vessel_name,
          "."
        ),
        paste0(
          "The following ",
          input$hwType,
          " was removed from the F/V ",
          input$vessel_name,
          ": ",
          input$hwRemoved
        )
      )
      statement2=ifelse(
        input$hwInstalled=="NA",
        paste0(
          "No new hardware was installed on the F/V ",
          input$vessel_name,
          "."
        ),
        paste0(
          "The following ",
          input$hwType,
          " was installed on the F/V ",
          input$vessel_name,
          ": ",
          input$hwInstalled
        )
      )
      ## Insert the record to the database once confirmed
      shinyalert(
        title="Equipment Confirmation",
        text=paste0(
          statement1,
          ". ",
          statement2),
        showConfirmButton=TRUE,
        confirmButtonText="Confirm",
        showCancelButton=TRUE,
        cancelButtonText="Edit",
        callbackR=function(x){
          if(x!=FALSE){
            ## Get the starting inventory ID
            start_inventory_id=ifelse(
              input$hwRemoved!="NA",
              dbGetQuery(
                conn=conn,
                statement=paste0(
                  "SELECT INVENTORY_ID FROM EQUIPMENT_INVENTORY WHERE SERIAL_NUMBER = ",
                  strsplit(input$hwRemoved," ")[[1]][1]
                )
              ),
              "NULL"
            )[[1]]
            ## Get the ending inventory ID
            end_inventory_id=ifelse(
              input$hwInstalled!="NA",
              dbGetQuery(
                conn=conn,
                statement=paste0(
                  "SELECT INVENTORY_ID FROM EQUIPMENT_INVENTORY WHERE SERIAL_NUMBER = ",
                  strsplit(input$hwInstalled," ")[[1]][1]
                )
              ),
              "NULL"
            )[[1]]
            port_id=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT PORT FROM PORTS WHERE PORT_NAME = '",
                input$port,
                "'"
              )
            )[1,1]
            vessel_id=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT VESSEL_ID FROM VESSELS WHERE VESSEL_NAME = '",
                input$vessel_name,
                "'"
              )
            )[1,1]
            ## Form the .json and POST it to the API
            POST(
              url='http://76.24.249.119:7777/equipment_install_removal',
              body=list(
                "vessel_id"=vessel_id,
                "contact_id"=757,
                "port"=port_id,
                "visit_date"=vdate,
                "visit_time"=vtime,
                "visit_notes"=input$notes,
                "equip_removed"=hwRemoved,
                "equip_installed"=hwInstalled
              ),
              encode='json'
            )
            cat(vessel_id,"\n",757,"\n",port_id,"\n",vdate,vtime,"\n",input$notes,"\n",hwRemoved,"\n",hwInstalled)
            shinyalert(
              title="Confirmation",
              text="Equipment record successfully added"
            )
            removeModal()
          }
        }
      )
    }
  )
  ## SAVE AND ADD ANOTHER
  ## Produce a human-readable version of the equipment record to be inserted 
  ## into the database and ask the user for confirmation
  observeEvent(
    input$saa,{
      statement1=ifelse(
        input$hwRemoved=="NA",
        paste0(
          "No hardware was removed from the F/V ",
          input$vessel_name,
          "."
        ),
        paste0(
          "The following ",
          input$hwType,
          " was removed from the F/V ",
          input$vessel_name,
          ": ",
          input$hwRemoved
        )
      )
      statement2=ifelse(
        input$hwInstalled=="NA",
        paste0(
          "No new hardware was installed on the F/V ",
          input$vessel_name,
          "."
        ),
        paste0(
          "The following ",
          input$hwType,
          " was installed on the F/V ",
          input$vessel_name,
          ": ",
          input$hwInstalled
        )
      )
      ## Insert the record to the database once confirmed
      shinyalert(
        title="Equipment Confirmation",
        text=paste0(
          statement1,
          ". ",
          statement2),
        showConfirmButton=TRUE,
        confirmButtonText="Confirm",
        showCancelButton=TRUE,
        cancelButtonText="Edit",
        callbackR=function(x){
          if(x!=FALSE){
            ## Get the starting inventory ID
            start_inventory_id=ifelse(
              input$hwRemoved!="NA",
              dbGetQuery(
                conn=conn,
                statement=paste0(
                  "SELECT INVENTORY_ID FROM EQUIPMENT_INVENTORY WHERE SERIAL_NUMBER = ",
                  strsplit(input$hwRemoved," ")[[1]][1]
                )
              ),
              "NULL"
            )[[1]]
            ## Get the ending inventory ID
            end_inventory_id=ifelse(
              input$hwInstalled!="NA",
              dbGetQuery(
                conn=conn,
                statement=paste0(
                  "SELECT INVENTORY_ID FROM EQUIPMENT_INVENTORY WHERE SERIAL_NUMBER = ",
                  strsplit(input$hwInstalled," ")[[1]][1]
                )
              ),
              "NULL"
            )[[1]]
            ## Get the visit ID
            port_id=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT PORT FROM PORTS WHERE PORT_NAME = '",
                input$port,
                "'"
              )
            )[1,1]
            vessel_id=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT VESSEL_ID FROM VESSELS WHERE VESSEL_NAME = '",
                input$vessel_name,
                "'"
              )
            )[1,1]
            statement=paste0(
              "SELECT VISIT_ID FROM VESSEL_VISIT_LOG WHERE VESSEL_ID = ",
              vessel_id,
              " AND PORT = ",
              port_id,
              " AND VISIT_DATE = '",
              paste0(
                input$vdate,
                " ",
                format.Date(
                  input$vtime,
                  "%H:%M:%S"
                ),
                "'"
              )
            )
            visit_id=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT VISIT_ID FROM VESSEL_VISIT_LOG WHERE VESSEL_ID = ",
                vessel_id,
                " AND PORT = ",
                port_id,
                " AND VISIT_DATE = '",
                paste0(
                  input$vdate,
                  " ",
                  format.Date(
                    input$vtime,
                    "%H:%M:%S"
                  ),
                  "'"
                )
              )
            )[1,1]
            statement=paste0(
              "INSERT INTO `EQUIPMENT_CHANGE` (`EQUIPMENT_CHANGE_ID`,`START_INVENTORY_ID`,`END_INVENTORY_ID`,`VISIT_ID`) VALUES(0,",
              start_inventory_id,
              ",",
              end_inventory_id,
              ",",
              visit_id,
              ")"
            )
            dbGetQuery(
              conn=conn,
              statement=statement
            )
            ## UPDATE THE EQUIPMENT LOCATION AND CUSTODIAN
            ## Removed equipment
            if(start_inventory_id!="NULL"){
              captain=dbGetQuery(
                conn=conn,
                statement=paste0(
                  "SELECT OPERATOR FROM VESSELS WHERE VESSEL_ID = ",
                  vessel_id
                )
              )
              dbGetQuery(
                conn=conn,
                statement=paste0(
                  "UPDATE EQUIPMENT_INVENTORY SET CURRENT_LOCATION = 'HOME', CUSTODIAN = ",
                  757,
                  " WHERE INVENTORY_ID = ",
                  start_inventory_id
                )
              )
            }
            ## Installed equipment
            if(end_inventory_id!="NULL"){
              captain=dbGetQuery(
                conn=conn,
                statement=paste0(
                  "SELECT OPERATOR FROM VESSELS WHERE VESSEL_ID = ",
                  vessel_id
                )
              )$OPERATOR[1]
              dbGetQuery(
                conn=conn,
                statement=paste0(
                  "UPDATE EQUIPMENT_INVENTORY SET CURRENT_LOCATION = 'VESSEL', CUSTODIAN = ",
                  captain,
                  " WHERE INVENTORY_ID = ",
                  end_inventory_id
                )
              )
            }
            shinyalert(
              title="Confirmation",
              text="Equipment record successfully added"
            )
          }
        }
      )
    }
  )
  ## ADD A NEW VISIT
  ## Produce a human-readable version of the visit record to be inserted into
  ## the database and ask the user for confirmation
  observeEvent(
    input$checkRecord,{
      visit_date=paste0(
        input$vdate,
        " ",
        format.Date(
          input$vtime,
          "%H:%M:%S"
        )
      )
      dups=dbGetQuery(
        conn=conn,
        statement=paste0(
          "SELECT VISIT_DATE, VESSEL_NAME, PORT_NAME FROM VESSEL_VISIT_VIEW WHERE VESSEL_NAME = '",
          input$vessel_name,
          "' AND VISIT_DATE = '",
          visit_date,
          "' AND PORT_NAME = '",
          input$port,
          "'"
        )
      )
      dups$VISIT_DATE=round_date(
        ymd_hms(dups$VISIT_DATE),
        unit="day"
      )
      if(nrow(dups)>0){
        shinyalert(
          title="Possible Duplicate Record(s) Found",
          text=paste(
            unite(dups, " ")[,1],
            sep="\n"),
          type="warning"
        )
      }
      shinyalert(
        title="Confirmation Dialogue",
        text=paste0(
          "Please confirm adding the following record: ",
          757,
          " visited the F/V ",
          input$vessel_name,
          " in ",
          input$port,
          ", ",
          input$state,
          " on ",
          input$vdate,
          ". The following notes were recorded: ",
          input$notes
        ),
        showConfirmButton=TRUE,
        confirmButtonText="CONFIRM",
        showCancelButton=TRUE,
        cancelButtonText="EDIT",
        callbackR=function(x){ 
          if(x != FALSE){
            vessel_id=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT VESSEL_ID FROM VESSELS WHERE VESSEL_NAME = '",
                input$vessel_name,
                "'"
              )
            )
            visit_date=paste0(
              input$vdate,
              " ",
              format.Date(
                input$vtime,
                "%H:%M:%S"
              )
            )
            lead_tech=757
            port=dbGetQuery(
              conn=conn,
              statement=paste0(
                "SELECT PORT FROM PORTS WHERE PORT_NAME = '",
                input$port,
                "'"
              )
            )
            statement=paste0(
              "INSERT INTO `VESSEL_VISIT_LOG` (`VISIT_ID`,`VESSEL_ID`,`VISIT_DATE`,`LEAD_TECH`,`PORT`,`VISIT_NOTES`) VALUES(0,",
              vessel_id,
              ",'",
              visit_date,
              "',",
              lead_tech,
              ",",
              port,
              ",'",
              input$notes,
              "')"
            )
            dbGetQuery(
              conn=conn,
              statement=statement
            )
            shinyalert(
              title="Confirmation",
              text="Visit record successfully added"
            )
            shinyalert(
              title="Hardware Questionnaire",
              text="Did you add or remove hardware from the vessel?",
              showCancelButton=TRUE,
              cancelButtonText="NO",
              showConfirmButton=TRUE,
              confirmButtonText="YES",
              callbackR=function(y){
                if(y==TRUE){
                  showModal(
                    modalDialog(
                      title="Hardware Testing",
                      fluidRow(
                        column(
                          width=6,
                          selectInput(
                            inputId='hwType',
                            label="Hardware Type: ",
                            choices=dbGetQuery(
                              conn=conn,
                              statement="SELECT EQUIPMENT_TYPE FROM EQUIPMENT_INVENTORY ORDER BY EQUIPMENT_TYPE"
                            )$EQUIPMENT_TYPE
                          ),
                          selectInput(
                            inputId='hwRemoved',
                            label="Hardware Removed: ",
                            choices=rbind(
                              "NA",
                              unite(
                                dbGetQuery(
                                  conn=conn,
                                  statement="SELECT SERIAL_NUMBER, MAKE, MODEL FROM EQUIPMENT_INVENTORY ORDER BY SERIAL_NUMBER"
                                ),
                                col="x",
                                remove=TRUE,
                                sep=" "
                              )$x
                            )
                          ),
                          selectInput(
                            inputId='hwInstalled',
                            label="Hardware Installed: ",
                            choices=rbind(
                              "NA",
                              unite(
                                dbGetQuery(
                                  conn=conn,
                                  statement="SELECT SERIAL_NUMBER, MAKE, MODEL FROM EQUIPMENT_INVENTORY ORDER BY SERIAL_NUMBER"
                                ),
                                col="x",
                                remove=TRUE,
                                sep=" "
                              )$x
                            )
                          ),
                          actionButton(
                            inputId="saa",
                            label="Save and Add Another"
                          ),
                          actionButton(
                            inputId="sae",
                            label="Save and Exit"
                          ),
                          modalButton(
                            label="Exit without saving"
                          )
                        )
                      ),
                      footer=NULL
                    )
                  )
                }
              }
            )
          }
        }
      )
    }
  )
}

# Run the application 
shinyApp(ui = ui, server = server)