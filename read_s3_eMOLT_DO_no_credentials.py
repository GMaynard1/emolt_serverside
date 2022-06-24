# Routine to grab Lowell Instrument DO data from AWS, plot, and process it.
# Original "read_s3_eMOLT.py" version by Carles & JiM processed the TD data
# This version modified by JiM in late June 2022 processes DO data.
# We should probably combine the two with some sort of class structure in the future.
# We might also want to have plotting routine in a separate code or function.
# Require module "emolt_functions.py" including the get_depth function which returns NGDC depths
# OUTPUT:
#   - emolt_do.dat haul average temperatures in the same format as "emolt.dat"
#   - raw merged csv file with header in the same format as other emolt csv files
#   - two panel plot with temperature and DO 
# See hardcodes below.
# REMEMBER TO REMOVE AWS credential before uploading to github
#
import boto3
import os
import pandas as pd
import numpy as np
import io
from matplotlib import pyplot as plt
import matplotlib.dates as mdates
import warnings
warnings.filterwarnings('ignore')
import emolt_functions

## HARDCODES ###############################
min_haul_time=5 # number of minutes considered for hauling on deck
min_equilibrate=15 # number of minutes to allow Lowell probe to equilibrate
est_depth='no' # 'yes' to use NGDC depths
vessel='Boat_of_Jim'
mac='60-77-71-22-c9-cd/'
vn='99' #KM
sensor='li_' # li_ for Lowell Instruments

# eMOLT credentials (WARNING: THESE NEEDED TO BE REMOVED BEFORE UPLOADING TO GITHUB)
access_key = ''
access_pwd = ''

s3_bucket_name = 'bkt-cfa'  # bucket name
path = 'aws_files/'  # path to store the data
outfile='emolt_do.dat'
### END OF HARDCODES ############################################


f_output=open(path+outfile,'w') # thiS is the haul averaged stats that we will add to other data
    
            
"""Accessing the S3 buckets using boto3 client"""
s3_client = boto3.client('s3')
s3 = boto3.resource('s3',
                    aws_access_key_id=access_key,
                    aws_secret_access_key=access_pwd)

""" Getting data files from the AWS S3 bucket with specified MAC address as denoted above """
my_bucket = s3.Bucket(s3_bucket_name)
bucket_list = []
for file in my_bucket.objects.filter(Prefix=mac):  # write the subdirectory name mac add
    file_name = file.key
    if (file_name.find(".csv") != -1) or (file_name.find(".gps") != -1): # JiM added gps
            bucket_list.append(file.key)

# next make sure there are csv files for each gps file
badind=[]
for k in range(len(bucket_list)):
    if bucket_list[k][-4:]=='.gps':
        if bucket_list[k][:-4]+'_DissolvedOxygen.csv' not in bucket_list:
            print(bucket_list[k]+' missing csv files')
            badind.append(k)
for e in badind:
    del bucket_list[e]

length_bucket_list = (len(bucket_list))

# Here's we we actually get the data from the bucket and generate dataframes
ldf_do = []  # Initializing empty list of dataframes
ldf_gps =[]
ldf_wd=[]

for file in bucket_list:
    obj = s3.Object(s3_bucket_name, file)
    data = obj.get()['Body'].read()
    try:
        if ('DissolvedOxygen' in os.path.basename(file)):# & (file[0:-16]+'.gps' in bucket_list):
            df = pd.read_csv(io.BytesIO(data), header=0, delimiter=",", low_memory=False)
            ldf_do.append(df)
        elif 'gps' in os.path.basename(file):
            df = pd.read_csv(io.BytesIO(data), header=0, delimiter=",", low_memory=False) # need to read this differently
            ldf_gps.append(df)
        elif 'WaterDetect' in os.path.basename(file):
            df = pd.read_csv(io.BytesIO(data), header=0, delimiter=",", low_memory=False) # need to read this differently
            ldf_wd.append(df)
    except:
        print('Not working', file)

# merging the dataframes
count=0
filenames = [i for i in bucket_list  if 'gps' in i] # where bucket_list is 3 times as many elements as filenames
for j in range(len(ldf_gps)): # for each set of files
    if max(ldf_wd[j]['Water Detect (%)'])>0: # only process those that were submerged
        print(filenames[j]+' has data!!')
        lat=ldf_gps[j].columns[0].split(' ')[1]# picks up the "column name" of an empty dataframe read by read_csv
        lon=ldf_gps[j].columns[0].split(' ')[2]
        ldf_do[j]['ISO 8601 Time']=pd.to_datetime(ldf_do[j]['ISO 8601 Time'])
        dfall=ldf_do[j]
        dfall['wd']=ldf_wd[j]['Water Detect (%)']
        dfall=dfall.set_index('ISO 8601 Time')
        dfall['Depth (m)']=999#ldf_pressure[j]['Pressure (dbar)'].values-correct_dep
        dfall['lat']=lat[1:]# removes the "+"
        dfall['lon']=lon
        dfall=dfall[dfall['wd']>0] # here's where we eliminate all data that is not detecting water
        #dfall=dfall[dfall['Depth (m)']>frac_dep*np.max(dfall['Depth (m)'])] # get bottom temps
        ids=list(np.where(np.diff(dfall.index)>np.timedelta64(min_haul_time,'m'))[0])# index of new hauls
        if len(ids)<=1:
            ids=[0,1]# use this to plot the entire file
        #else:
        #    continue
        for kk in range(len(ids)-1):     # loop through each haul and process individual haul       
          #df=dfall[ids[kk]+min_equilibrate:ids[kk+1]] # ignores "min_equilibrate" minutes at start
          df=dfall[0+min_equilibrate:-1] # for the case of one haul
          if not df.empty:
            # Here is where we might look into "track" file to find the correct gps position for this particular haul
            #[lat,lon]=getgps(df.index[-1],track_file) (se read_s3_emolt.py for this function)
            # Find mean haul stats as done in the "rock_getmatp.py" routine:
            meantemp=str(round(np.mean(df['DO Temperature (C)'][0:-2]),2))
            sdeviatemp=str(round(np.std(df['DO Temperature (C)'][0:-2]),2))
            timelen=str(int(len(df))) #logger time interval is 1 minutes put in hours
            if est_depth=='yes':
                #meandepth=str(round(np.mean(df['Depth (m)'].values),1))
                print('getting depth estimate from NGDC ...')
                meandepth=str(round(emolt_functions.get_depth(float(lon),float(lat),0.5),1))# estimates depth from NGDC database
            else:
                meandepth='999.0'
            rangedepth='0.0'#str(round(max(df['Depth (m)'].values)-min(df['Depth (m)'].values),1))
            
            # Write out to emolt_AWS.dat
            # f_output.write(str(id_idn1).rjust(10)+" "+str(esn[-6:]).rjust(7)+ " "+str(mth1).rjust(2)+ " " +
            f_output.write(" 999 999 "+str(df.index[0].month).rjust(2)+ " " +
                str(df.index[0].day).rjust(2)+" " +str(df.index[0].hour).rjust(3)+ " " +str(df.index[0].minute).rjust(3)+ " " )
            f_output.write(("%10.7f") %(df.index[0].day_of_year+df.index[0].hour/24.+df.index[0].minute/60/24.))
            f_output.write(" "+lon+' '+lat+' '+meandepth+" "+str(np.nan))
            f_output.write(" "+meandepth+' '+rangedepth+' '+timelen + ' '+meantemp+ " "
                  +sdeviatemp+' '+str(df.index[0].year)+'\n')
            
            fig=plt.figure(figsize=(8,5))
            ax = fig.add_subplot(211)
            ax.plot(df.index,df['DO Temperature (C)'],'r.')
            ax.set_ylim(min(df['DO Temperature (C)'].values),max(df['DO Temperature (C)'].values))
            TF=df['DO Temperature (C)'].values*1.8+32 # temp in farenheit
            ax.set_ylabel('degC',color='r')
            ax.tick_params(labelbottom=False)
            ax2=ax.twinx()
            ax2.set_ylim(min(TF),max(TF))
            ax2.plot(df.index,TF,'r.')
            ax2.set_ylabel('fahrenheit',color='r')
            #ax.xaxis.set_major_formatter(dates.DateFormatter('%M'))
            ##plt.title(vessel+' at '+str(lat[:-3])+'N, '+str(lon[:-3])+'W')# where we ignore the last 3 digits of lat/lon
            plt.title(vessel)
            ax3 = fig.add_subplot(212)
            ax3.plot(df.index,df['Dissolved Oxygen (%)'],'g.')
            ax3.set_ylabel('%',color='g')
            ax4=ax3.twinx()
            #ax4.set_ylim(min(DF),max(DF))
            ax4.plot(df.index,df['Dissolved Oxygen (mg/l)'],'b.')
            ax4.set_ylabel('mg/l',color='b')
            ax4.xaxis.set_major_formatter(mdates.DateFormatter("%b %d %H:%M"))
            ax3.tick_params(axis='x', rotation=45)
            
            plt.subplots_adjust(bottom=0.19)
            #plt.xticks(rotation=90)
            #fig.autofmt_xdate()
            plt.show()
            plt.savefig('c:/Users/james.manning/Downloads/emolt_realtime/aws_plots/'+vessel+'/'+vessel+filenames[j][-18:-4]+'_'+str(kk)+'.png')
            #plt.savefig('aws_plots/'+vessel+filenames[j][-18:-4]+'_'+str(kk)+'.png')
            #plt.close('all')
            df.reset_index(level=0, inplace=True)
            df=df.rename(columns={'ISO 8601 Time':'Datet(GMT)'})#, 'Temperature (C)': 'Temperature(C)', 'depth (m)': 'Depth(m)'},inplace=True)
            df['HEADING'] = 'DATA'
            df=df.set_index('HEADING')
            outputfile='aws_files/li_'+filenames[j][12:14]+filenames[j][15:17]+'_'+filenames[j][-18:-8]+'_'+filenames[j][-8:-4]+'_'+vessel+'.csv'
            df.to_csv(outputfile)
            # NOW PUT A STANDARD HEADER ON THIS FILE
            f=open(outputfile,'r+')
            content = f.read()
            f.seek(0, 0)
            f.writelines('Probe Type,{sensor}\nSerial Number,'.format(sensor=sensor) + mac[:-1] + '\nVessel Number,' + vn + '\nVP_NUM, Nan \nVessel Name,' + vessel + '\nDate Format,YYYY-MM-DD\nTime Format,HH24:MI:SS\nTemperature,C\nDepth,m\n')  # create header with logger number
            f.write(content)
            f.close()
            emolt_functions.eMOLT_cloud([outputfile]) #uploads file                
f_output.close()
    