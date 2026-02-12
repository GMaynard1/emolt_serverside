# Routine to grab Lowell Instrument TD data from AWS 
# Original version by Carles w/some additions by JiM in Fall 2021
#
# This version:
# - accesses the AWS gps, temp, and pressure csv files
# - makes dataframes and then a merged csv file for each haul
# - generates a png plot file for each haul
# - generates a gif animation for the case of multi-haul files (optional)
# - calculates haul-avarege stats and uploads emolt_AWS.dat file to emolt_cloud
#
# Nov 2021 - JiM added GPS file grabbing
# Dec 2021 - JiM added plotting and haul averaged exports to "emolt_aws.dat"
# Jul 2022 - JiM added ability to process multi-haul files using a manually downloaded track file
#          - JiM put credentials in "config_aws_cfa.yml" file
#
# Note: Another routine called "read_s3_eMOLT_status.py" just reports on new data coming to AWS 
# Note: I still need to use George's database API functionality as I did in the _status version
#



## HARDCODES ##############################################
correct_dep=10. # correction for atmos pressure
frac_dep=0.5#0.85 # fraction of the depth consider "bottom"
min_depth=10.0 #10.0 meters by default  minimum depth (meters) acceptable for a cast
min_haul_time=5 # number of minutes considered for hauling on deck
min_equilibrate=10 #20 minutes to be safe (number of minutes to allow Lowell probe to equilibrate)
#vessel=['Beast_of_Burden','Kathyrn_Marie','Mary_Elizabeth','Miss_Emma','Princess_Scarlett']#,'Miss_Julie']
#mac=['00-1e-c0-6c-75-1d/','00-1e-c0-6c-76-10/','00-1e-c0-6c-74-f1/','00-1e-c0-6c-75-02/','00-1e-c0-6c-76-19/','cf-d4-f1-9d-8d-a8/']
#vn=['56','59','57','62','60']
#vessel='Kathyrn_Marie'
#mac='00-1e-c0-6c-76-10/'
#vn='59' #KM
#vessel='Miss_Emma'
#mac='00-1e-c0-6c-75-02/'
#vn='57' #
#vessel='Miss_Julie'
#mac='cf-d4-f1-9d-8d-a8/'
#vn='63'
vessel='Princess_Scarlett'
mac='00-1e-c0-6c-76-19/'
vn='60'
sensor='li_' # li_ for Lowell Instruments
YRMTHDAY=20220709# year month day to start process
path = 'c:/Users/james.manning/Downloads/emolt_realtime/aws_files/'  # path to store the data
track_file=path+'track_'+vessel+'_20220714135608.txt'# where this is manually downloaded for multi-haul cases
#gif_filename='Chatham_June2022'
pltdir='c:/Users/james.manning/Downloads/emolt_realtime/aws_plots/'
s3_bucket_name = 'bkt-cfa'  # bucket name
f_output=open(path+'emolt_AWS.dat','w')
####  END  OF HARDCODE SECTION ########################

import boto3
import glob
import imageio
import sys
import os
import pandas as pd
import numpy as np
import csv
import io
import ftplib
from io import StringIO
from matplotlib import pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime as dt
from datetime import timedelta as td
import warnings
warnings.filterwarnings('ignore')
import importlib
import time
from reformat_emolt import add_eMOLT_header
import yaml

## read credentials from yaml file
with open ("config_aws_cfa.yml","r") as yamlfile:
  dbConfig=yaml.load(yamlfile, Loader=yaml.FullLoader)
  access_key = dbConfig['default']['db_remote']['username']
  access_pwd = dbConfig['default']['db_remote']['password']
  
    
def eMOLT_cloud(ldata):
        # function to upload a list of files to SD machine
        for filename in ldata:
            # print u
            session = ftplib.FTP('66.114.154.52', 'huanxin', '123321')
            file = open(filename, 'rb')
            #session.cwd("/BDC")
            # session.retrlines('LIST')               # file to send
            session.storbinary("STOR " + filename.split('/')[-1], fp=file)  # send the file
            # session.close()
            session.quit()  # close file and FTP
            time.sleep(1)
            file.close()
            print(filename.split('/')[-1], 'uploaded in eMOLT endpoint')
            
def getgps(endhaultime,track_file):
    # endhaultime is a time stamp
    dft=pd.read_csv(track_file,sep='|',names=['dt_str','latlon'])
    dft['dtime']=pd.to_datetime(dft['dt_str'])
    dft=dft.set_index('dtime')
    idx = dft.index.get_loc(endhaultime.to_pydatetime(), method='nearest')
    if abs(dft.index[idx]-endhaultime)>td(hours=1):
        print('Sorry, there is no GPS data for this haul time in '+track_file)
        lat=99.
        lon=99.
        return str(lat),str(lon)
    lat,lon=[],[]
    for k in range(len(dft)):
        lat.append(float(dft['latlon'][k][2:11]))
        lon.append(float(dft['latlon'][k][12:]))
    lat=lat[idx]
    lon=lon[idx]
    return str(lat),str(lon)#lat,lon

def make_gif(gif_name,png_dir,frame_length = 0.2,end_pause = 4 ):
    '''use images to make the gif
    frame_length: seconds between frames
    end_pause: seconds to stay on last frame
    the format of start_time and end time is string, for example: %Y-%m-%d(YYYY-MM-DD)'''
    
    if not os.path.exists(os.path.dirname(gif_name)):
        os.makedirs(os.path.dirname(gif_name))
    allfile_list = glob.glob(os.path.join(png_dir,'*.png')) # Get all the pngs in the current directory
    file_list=allfile_list
    list.sort(file_list, key=lambda x: x.split('/')[-1].split('t')[0]) # Sort the images by time, this may need to be tweaked for your use case
    images=[]
    # loop through files, join them to image array, and write to GIF called 'wind_turbine_dist.gif'
    for ii in range(0,len(file_list)):       
        file_path = os.path.join(png_dir, file_list[ii])
        if ii==len(file_list)-1:
            for jj in range(0,int(end_pause/frame_length)):
                images.append(imageio.imread(file_path))
        else:
            images.append(imageio.imread(file_path))
    # the duration is the time spent on each image (1/duration is frame rate)
    imageio.mimsave(gif_name, images,'GIF',duration=frame_length)
    

###### MAIN ROUTINE STARTS HERE#################################            
"""Accessing the S3 buckets using boto3 client"""
s3_client = boto3.client('s3')
s3 = boto3.resource('s3',
                    aws_access_key_id=access_key,
                    aws_secret_access_key=access_pwd)

""" Getting data files from the AWS S3 bucket as denoted above """
my_bucket = s3.Bucket(s3_bucket_name)
bucket_list = []
#for file in my_bucket.objects.filter(Prefix='00-1e-c0-6c-74-f1/'):  # write the subdirectory name
for file in my_bucket.objects.filter(Prefix=mac):  # write the subdirectory name mac add
    file_name = file.key
    if (file_name.find(".csv") != -1) or (file_name.find(".gps") != -1): # JiM added gps
        try:
            yrmthday=int(file_name[34:42])# this picks up the yrmthday from the filename
            if yrmthday>YRMTHDAY:         # we usually are processing only those files after a certain user specified date
               bucket_list.append(file.key) 
        except:
            pass

## JiM sometime hardcodes bucket_list while working on a single file
'''
bucket_list=['00-1e-c0-6c-76-19/2110403_T&P_(0)_20220714012629.gps',
             '00-1e-c0-6c-76-19/2110403_T&P_(0)_20220714012629_Pressure.csv',
             '00-1e-c0-6c-76-19/2110403_T&P_(0)_20220714012629_Temperature.csv']

bucket_list=['00-1e-c0-6c-76-19/2110403_T&P_(0)_20220714180047.gps',
             '00-1e-c0-6c-76-19/2110403_T&P_(0)_20220714180047_Pressure.csv',
             '00-1e-c0-6c-76-19/2110403_T&P_(0)_20220714180047_Temperature.csv']
'''

length_bucket_list = (len(bucket_list))

""" Reading the individual files from the AWS S3 buckets and putting them in dataframes """
#
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

# merging the dataframes
count=0
filenames = [i for i in bucket_list  if 'gps' in i] # where bucket_list is 3 times as many elements as filenames
#filenames = ['00-1e-c0-6c-76-10/2110404_T&P_(0)_20220605200239.gps'] # JiM sometimes hardcodes when looking at one file
for j in range(len(ldf_gps)): # only process those with a GPS
    if max(ldf_pressure[j]['Pressure (dbar)'])-correct_dep>min_depth: # only process those that were submergedmore than "min_depth" meters
        print(filenames[j]+' has data!!')

        ldf_temperature[j]['ISO 8601 Time']=pd.to_datetime(ldf_temperature[j]['ISO 8601 Time'])# converts to datetime
        dfall=ldf_temperature[j]
        dfall=dfall.set_index('ISO 8601 Time')
        dfall['Depth (m)']=ldf_pressure[j]['Pressure (dbar)'].values-correct_dep # most of Nick's depths were off by 10m

        dfall=dfall[dfall['Depth (m)']>frac_dep*np.max(dfall['Depth (m)'])] # get bottom temps greater than "frac_dep" of water column
        ids=list(np.where(np.diff(dfall.index)>np.timedelta64(min_haul_time,'m'))[0])# index end of new hauls
        if len(ids)<=1: # case of just one haul for the file
            ids=[0,1]# use this to plot the entire file
            lat=ldf_gps[j].columns[0].split(' ')[1][1:]# picks up the "column name" of an empty dataframe read by read_csv
            lon=ldf_gps[j].columns[0].split(' ')[2]
            dfall['lat']=lat[1:]# removes the "+"
            dfall['lon']=lon
        numhauls=len(ids)-1
        for kk in range(numhauls):     # loop through each haul and process individual haul 
          if numhauls>1:
              print('Haul # '+str(kk))
              df=dfall[ids[kk]+min_equilibrate:ids[kk+1]] # ignores "min_equilibrate" minutes at start
              if df.empty:
                  print('empty or too short haul #'+str(kk)+' from '+str(dfall.index[kk])+' to '+str(dfall.index[kk+1]))
                  continue
              else:
                  # Here is where we should look into "track" file to find the correct gps position for this particular haul
                  [lat,lon]=getgps(df.index[-1],track_file)# gets the last position of the haul
          else:
              df=dfall[0+min_equilibrate:-1] # for the case of one haul
          if df.empty:
            print('empty')
            continue
          else:
            # Find mean haul stats as done in the "rock_getmatp.py" routine:
            meantemp=str(round(np.mean(df['Temperature (C)'][0:-2]),2))
            sdeviatemp=str(round(np.std(df['Temperature (C)'][0:-2]),2))
            timelen=str(int(len(df))) #logger time interval is 1 minutes put in hours
            meandepth=str(round(np.mean(df['Depth (m)'].values),1))
            rangedepth=str(round(max(df['Depth (m)'].values)-min(df['Depth (m)'].values),1))
            
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
            ax.plot(df.index,df['Temperature (C)'],color='r')
            ax.set_ylim(min(df['Temperature (C)'].values),max(df['Temperature (C)'].values))
            TF=df['Temperature (C)'].values*1.8+32 # temp in farenheit
            ax.set_ylabel('degC')
            ax.tick_params(labelbottom=False)
            ax2=ax.twinx()
            ax2.set_ylim(min(TF),max(TF))
            ax2.plot(df.index,TF,color='r')
            ax2.set_ylabel('fahrenheit')
            #ax.xaxis.set_major_formatter(dates.DateFormatter('%M'))
            ##plt.title(vessel+' at '+str(lat[:-3])+'N, '+str(lon[:-3])+'W')# where we ignore the last 3 digits of lat/lon
            plt.title(vessel)
            ax3 = fig.add_subplot(212)
            ax3.plot(df.index,-1*df['Depth (m)'])
            ax3.set_ylabel('meters')
            DF=-1*df['Depth (m)']/1.8288
            ax4=ax3.twinx()
            ax4.set_ylim(min(DF),max(DF))
            ax4.plot(df.index,TF,color='b')
            ax4.set_ylabel('fathoms')
            ax4.xaxis.set_major_formatter(mdates.DateFormatter("%b %d %H:%M"))
            ax3.tick_params(axis='x', rotation=45)
            plt.subplots_adjust(bottom=0.19)
            #plt.xticks(rotation=90)
            #fig.autofmt_xdate()
            plt.show()
            #plt.savefig('c:/Users/james.manning/Downloads/emolt_realtime/aws_plots/'+vessel+'/'+vessel+filenames[j][-18:-4]+'_'+str(kk)+'.png')
            plt.savefig(pltdir+vessel+'/'+vessel+filenames[j][-18:-4]+'_'+str(kk)+'.png')
            #plt.savefig('aws_plots/'+vessel+filenames[j][-18:-4]+'_'+str(kk)+'.png')
            plt.close('all')
            df.reset_index(level=0, inplace=True)
            df=df.rename(columns={'ISO 8601 Time':'Datet(GMT)'})#, 'Temperature (C)': 'Temperature(C)', 'depth (m)': 'Depth(m)'},inplace=True)
            df['HEADING'] = 'DATA'
            df=df.set_index('HEADING')
            #df.reset_index(level=0, inplace=True)
            #df.index = df['HEADING']
            #outputfile='aws_files/li_'+filenames[j][12:14]+filenames[j][15:17]+'_'+filenames[j][35:42]+'_'+filenames[j][43:48]+'_'+vessel+'.csv'
            outputfile='aws_files/li_'+filenames[j][12:14]+filenames[j][15:17]+'_'+filenames[j][-18:-8]+'_'+filenames[j][-8:-4]+'_'+vessel+'.csv'
            df.to_csv(outputfile)
            # NOW PUT A STANDARD HEADER ON THIS FILE
            f=open(outputfile,'r+')
            content = f.read()
            f.seek(0, 0)
            f.writelines('Probe Type,{sensor}\nSerial Number,'.format(sensor=sensor) + mac[:-1] + '\nVessel Number,' + vn + '\nVP_NUM, Nan \nVessel Name,' + vessel + '\nDate Format,YYYY-MM-DD\nTime Format,HH24:MI:SS\nTemperature,C\nDepth,m\n')  # create header with logger number
            f.write(content)
            f.close()
            #eMOLT_cloud([outputfile]) #uploads file
                
f_output.close()
#make_gif('c:/users/james.manning/emolt_realtime/aws_plots/'+gif_filename+'.gif','c:/users/james.manning/Downloads/emolt_realtime/aws_plots/test/', frame_length=2.0)
    