# Routine to check Lowell Instrument data from AWS 
# This "_status" version just counts the number of hauls from each vessel
# This is a reduced version of the routine that plot actual hauls, see "read_s3_eMOLT.py" which is an addition to Carles's original code.
# Gets mac addresses for each vessel from database
#
# Modified in August 2022 to generate a html listing of what vessels are reporting good data 

import boto3
import os
import pandas as pd
import numpy as np
import io
from emolt_functions import get_mac
from datetime import datetime as dt
from datetime import timedelta as td
import yaml

## HARDCODES ###
correct_dep=10. # correction for atmos pressure
frac_dep=0.75#0.85 # fraction of the depth consider "bottom"
min_depth=15.0 # minimum depth (meters) acceptable for a cast
min_haul_time=5 # number of minutes considered for hauling on deck
how_many_days_before_today_to_check=30 # only report data from the last XX days
outfile='emolt_aws_status.html'
### END OF HARDCODES ############################################


## read credentials from yaml file
with open ("config_aws_cfa.yml","r") as yamlfile:
  dbConfig=yaml.load(yamlfile, Loader=yaml.FullLoader)
  access_key = dbConfig['default']['db_remote']['username']
  access_pwd = dbConfig['default']['db_remote']['password']

# open an html file to report findings
f_html=open(outfile,'w')################
f_html.write('<html><style>.redtext {color: red;}</style>\n')
f_html.write('<h3>Status of AWS Lowell TD data</h3>\n')
f_html.write('<table id="table_id" border="1" class="display">\n')
f_html.write('<thead><tr><th>vessel</th><th>#hauls</th><th>lat</th><th>lon</th><th>DATE</th>')
f_html.write('<tbody>\n')
today=dt.now()
 
vessel=['Beast_of_Burden','Chatham','Mary_Elizabeth','Miss_Emma','Princess_Scarlett','Miss_Julie']
#vessel=['Beast_of_Burden']
# build a set of mac addresses using Georges's API and database 
mac=[]
for k in range(len(vessel)):
    mac.append(get_mac(vessel[k]).replace(':','-').lower()+'/')
# comment out the following if you do NOT want to rely solely on the mysql database
# mac=['00-1e-c0-6c-75-1d/','00-1e-c0-6c-76-10/','00-1e-c0-6c-74-f1/','00-1e-c0-6c-75-02/','00-1e-c0-6c-76-19/','cf-d4-f1-9d-8d-a8/']


# eMOLT credentials
# see yaml
s3_bucket_name = 'bkt-cfa'  # bucket name
path = 'aws_files/'  # path to store the data

#Accessing the S3 buckets using boto3 client
s3_client = boto3.client('s3')
s3 = boto3.resource('s3',
                    aws_access_key_id=access_key,
                    aws_secret_access_key=access_pwd)

#Getting data files from the AWS S3 bucket as denoted above 
my_bucket = s3.Bucket(s3_bucket_name)
bucket_list = []
for k in range(len(vessel)):
    for file in my_bucket.objects.filter(Prefix=mac[k]):  # write the subdirectory name mac add
        file_name = file.key
        if (file_name.find(".csv") != -1) or (file_name.find(".gps") != -1): # JiM added gps
            bucket_list.append(file.key)
    length_bucket_list = (len(bucket_list))

#l_downloaded = os.listdir(path) 
#bucket_list = [e for e in bucket_list if e not in l_downloaded] # new files not yet downloaded


# Reading the individual files from the AWS S3 buckets and putting them in dataframes 
ldf_pressure = []  # Initializing empty list of dataframes
ldf_temperature = []
ldf_gps =[]
for file in bucket_list:
    obj = s3.Object(s3_bucket_name, file)
    data = obj.get()['Body'].read()
    try:
        if ('Temperature' in os.path.basename(file)) & (file[0:-16]+'.gps' in bucket_list):
            df = pd.read_csv(io.BytesIO(data), header=0, delimiter=",", low_memory=False)
            ldf_temperature.append(df)
        elif ('Pressure' in os.path.basename(file)) & (file[0:-13]+'.gps' in bucket_list):
            df = pd.read_csv(io.BytesIO(data), header=0, delimiter=",", low_memory=False)
            ldf_pressure.append(df)
        elif 'gps' in os.path.basename(file):
            df = pd.read_csv(io.BytesIO(data), header=0, delimiter=",", low_memory=False) # need to read this differently
            ldf_gps.append(df)
    except:
        print('Not working', file)

# Note: ldf_pressure, ldf_temperature,ldf_gps are lists of dataframes
# merging the dataframes
count=0
filenames = [i for i in bucket_list  if 'gps' in i] # where bucket_list is 3 times as many elements as filenames
for j in range(len(ldf_gps)): # only process those with a GPS
    if max(ldf_pressure[j]['Pressure (dbar)'])>min_depth: # only process those that were submergedmore than "min_depth" meters
        lat=ldf_gps[j].columns[0].split(' ')[1][1:]# picks up the "column name" of an empty dataframe read by read_csv
        if lat[0]=='/':#case when lat/lon is not is listed in gps file as 'N/A'
            lat='N/A'
        lon=ldf_gps[j].columns[0].split(' ')[2]
        ldf_temperature[j]['ISO 8601 Time']=pd.to_datetime(ldf_temperature[j]['ISO 8601 Time'])
        dfall=ldf_temperature[j]
        dfall=dfall.set_index('ISO 8601 Time')
        dfall['depth (m)']=ldf_pressure[j]['Pressure (dbar)'].values-correct_dep
        dfall['lat']=lat[1:]# removes the "+"
        dfall['lon']=lon
        dfall=dfall[dfall['depth (m)']>frac_dep*np.max(dfall['depth (m)'])] # get bottom temps
        ids=list(np.where(np.diff(dfall.index)>np.timedelta64(min_haul_time,'m'))[0])# index of new hauls
        count=count+len(ids)
        v=vessel[np.where(np.array(mac) == filenames[j][:18])[0][0]]
        f_html.write('<tr><td>'+v+'<td>'+str(len(ids)+1)+'<td>'+str(lat)+'<td>'+str(lon)+'<td>'+str(dfall.index[0])[0:10])
        if dfall.index[0].to_pydatetime()>today-td(days=how_many_days_before_today_to_check):
            if lat[0:2].isdigit():
                #print(v+' has '+str(len(ids)+1)+' hauls at '+str(lat)+'N, '+str(lon)+'W in '+filenames[j][18:-4])
                print(v+' has '+str(len(ids)+1)+' hauls at '+str(lat)+'N, '+str(lon)+'W on '+str(dfall.index[0])[0:10])
                
            else:
                print(v+' has '+str(len(ids)+1)+' hauls with no GPS on '+str(dfall.index[0])[0:10])
            
print('\nTotal hauls ='+str(count))
f_html.write('</tbody></table>')
f_html.write('Total # hauls ='+str(count))
f_html.close()
