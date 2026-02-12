from fastapi import FastAPI
from pydantic import BaseModel
from app.utils.connect_from_config import *

## Define message class
class Message(BaseModel):
    data: str
    serial: str
    imei: str
    transmit_time: str

app=FastAPI()

@app.post("/messages/")
async def create_message(message: Message):
    conn = connect_from_config.db_connect_from_config("app/utils/dev_db_ddh.yml")
    cur = conn.cursor()
    data = message.data
    serial = message.serial
    imei = message.imei
    transmit_time = message.transmit_time
    query = "INSERT INTO fastapi_test (data, serial, imei, transmit_time) VALUES (%s, %s, %s, %s)"
    val=(data, serial, imei, transmit_time)
    cur.execute(query, val)
    conn.commit()
    query2 = "SELECT * FROM fastapi_test LIMIT 5"
    cur.execute(query2)
    mess_info = cur.fetchall()
    return(mess_info)
