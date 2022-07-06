# -*- coding: utf-8 -*-
"""
Created on Tue Jun 28 13:30:26 2022
generating haul-averaged bottom temps from ODN's ERDDAP-served trawlers
Note: removed IP address to keep access limited 

@author: James.manning
"""
import pandas as pd
import numpy as np
from emolt_functions import eMOLT_cloud
f_output=open('emolt_navy.dat','w')
url='http://<ip_address_goes_here>/erddap/tabledap/ONR_FV_NRT.csvp?tow_id%2Ctime%2Clatitude%2Clongitude%2Cdepth%2Ctemperature%2Cvessel_id%2Csegment_type&segment_type=%22Fishing%22'
df=pd.read_csv(url)
df['datetime']=pd.to_datetime(df['time (UTC)']).dt.tz_localize(None)
df.set_index('datetime',inplace=True)
hauls=np.unique(df['tow_id'])
for k in hauls: # loop through all the hauls
    df1=df[df['tow_id']==k]
    # calculate statistics for this haul
    meantemp=str(round(np.mean(df1['temperature (degree_C)'][0:-2]),2))
    sdeviatemp=str(round(np.std(df1['temperature (degree_C)'][0:-2]),2))
    #timelen=((df1['datetime'].max()-df1['datetime'].min()).total_seconds()/60)#length of tow in minutes
    timelen=str(round((df1.index.max()-df1.index.min()).total_seconds()/60)).rjust(4)
    rangedepth=str(round(max(df1['depth (m)'].values)-min(df1['depth (m)'].values),1))
    meandepth=str(round(np.mean(df1['depth (m)'])))#'][0:-2]),2))
    # Write out in our standard emolt.dat format
    f_output.write(str(df1['vessel_id'][0]).rjust(7)+str(k).rjust(10)+" "+str(df1.index[0].month).rjust(2)+ " " +
        str(df1.index[0].day).rjust(2)+" " +str(df1.index[0].hour).rjust(3)+ " " +str(df1.index[0].minute).rjust(3)+ " " )
    f_output.write(("%10.7f") %(df1.index[0].day_of_year+df1.index[0].hour/24.+df1.index[0].minute/60/24.))
    #f_output.write(" "+str(df1['longitude (degrees_east)'][0]).rjust(4)+' '+str(df1['latitude (degrees_north)'][0]).rjust(4)+' '+meandepth+" "+str(np.nan))
    f_output.write("%9.4f" %df1['longitude (degrees_east)'][0]+"%10.4f" %df1['latitude (degrees_north)'][0]+' '+meandepth+" "+str(np.nan))
    f_output.write(" "+meandepth+' '+rangedepth+' '+timelen + ' '+meantemp+ " "
          +sdeviatemp+' '+str(df1.index[0].year)+'\n')
f_output.close()
eMOLT_cloud(['emolt_navy.dat'])
