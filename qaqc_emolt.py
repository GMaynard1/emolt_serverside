# routine to check the quality of real-time eMOLT data
# where it looks for outliers and compares obs to historical means
# flag = 0 good, flag=1 near dock, flag=2 bad temp, flag=3 depth out of range, and flag=4 depth not near NGDC bottom depth 
# Author: JiM in late 2018
# Modification in Apr 2019 to add check on depth compared to NGDC estimates
# Modification in Oct 2019 to output "good" only as emolt_QCed_good.csv
# only <50m apply on flag 4 , Jun 2021

import pandas as pd
import numpy as np
from datetime import datetime as dt
from conversions import dd2dm
import netCDF4

####
# HARDCODES
min_miles_from_dock=2 # minimum miles from a dock position to be considered ok (this is not actual miles but minutes of degrees)
temp_ok=[0,30]    # acceptable range of mean temps
depth_ok=[10,500] # acceptable range of mean depths (meters)
fraction_depth_error=0.2 # acceptable difference of observed bottom vs NGDC
mindist_allowed=0.4 # minimum distance from nearest NGDC depth in km 
def nearlonlat(lon,lat,lonp,latp): 
    """
    i=nearlonlat(lon,lat,lonp,latp) change
    find the closest node in the array (lon,lat) to a point (lonp,latp)
    input:
        lon,lat - np.arrays of the grid nodes, spherical coordinates, degrees
        lonp,latp - point on a sphere
        output:
            i - index of the closest node
            For coordinates on a plane use function nearxy          
            Vitalii Sheremet, FATE Project  
    """
    cp=np.cos(latp*np.pi/180.)
    # approximation for small distance
    dx=(lon-lonp)*cp
    dy=lat-latp
    dist2=dx*dx+dy*dy
    i=np.argmin(dist2)
    return i 

def gps_compare_JiM(lat,lon,harbor_range): #check to see if the boat is in the harbor derived from Huanxin's "wifipc.py" functions   
    # function returns yes if this position is with "harbor_range" miles of a dock
    file='/var/www/vhosts/emolt.org/huanxin_ftp/harborlist.txt' # has header line lat, lon, harbor
    df=pd.read_csv(file,sep=',')
    [la,lo]=dd2dm(lat,lon) # converted decimal degrees to degrees minutes
    indice_lat=[i for i ,v in enumerate(abs(np.array(df['lat'])-la)<harbor_range) if v]
    indice_lon=[i for i ,v in enumerate(abs(np.array(df['lon'])-lo)<harbor_range) if v]
    harbor_point_list=[i for i, j in zip(indice_lat,indice_lon) if i==j]
    if len(harbor_point_list)>0:
       near_harbor='yes'
    else:
       near_harbor='no'
    return near_harbor #yeas or no

def get_depth(loni,lati,mindist_allowed):
    # routine to get depth (meters) using vol1 from NGDC
    try:
        if lati>40:
            url='https://www.ngdc.noaa.gov/thredds/dodsC/crm/crm_vol1.nc'
        else:
            url='https://www.ngdc.noaa.gov/thredds/dodsC/crm/crm_vol2.nc'
        nc = netCDF4.Dataset(url).variables 
        lon=nc['x'][:]
        lat=nc['y'][:]
        xi,yi,min_dist= nearlonlat_zl(lon,lat,loni,lati) 
        if min_dist>mindist_allowed:
          depth=np.nan
        else:
          depth=nc['z'][yi,xi].data
    except:
        url='https://coastwatch.pfeg.noaa.gov/erddap/griddap/srtm30plus_LonPM180.csv?z%5B(33.):1:(47.)%5D%5B(-78.):1:(-62.)%5D'  
        df=pd.read_csv(url)
        lon=df['longitude'].values[1:].astype(np.float)
        lat=df['latitude'].values[1:].astype(np.float)
        i= nearlonlat(lon,lat,loni,lati)
        depth=df['z'].values[i]
      
    return float(depth)#,min_dist

def nearlonlat_zl(lon,lat,lonp,latp): # needed for the next function get_FVCOM_bottom_temp 
    """ 
    used in "get_depth"
    """ 
    # approximation for small distance 
    cp=np.cos(latp*np.pi/180.) 
    dx=(lon-lonp)*cp
    dy=lat-latp 
    xi=np.argmin(abs(dx)) 
    yi=np.argmin(abs(dy))
    min_dist=111*np.sqrt(dx[xi]**2+dy[yi]**2)
    return xi,yi,min_dist

######################################
#  MAIN PROGRAM
colnames=['vessel','esn','mth','day','hr_gmt','mn','yd','lon','lat','dum1','dum2','depth','depth_range','time_hours','mean_temp','std_temp','year']
#df=pd.read_csv('/net/pubweb_html/drifter/emolt.dat',sep='\s+',names=colnames,header=None)
df=pd.read_csv('http://emolt.org/emoltdata/emolt.dat',sep='\s+',names=colnames,header=None)
already_calculated_depth_ngdc=np.load('/var/www/vhosts/emolt.org/huanxin_ftp/weekly_project/result/already_calculated_depth_ngdc.npy')
# go through file line by line, create a datetime, and also create "flag" for each observation where:
# 0 is good data
# 1 is data from the dock
# 2 is bad mean temperature
# 3 is bad out of range depth
# 4 is depth not near bottom (<85% of water columne depth)
# 5 is bad lat/lons not on the NE coast shelf
#print ('Note: ',str(len(already_calculated_depth_ngdc)),' NGDC depths already calculated.')
datet,flag,hours,save_depth_ngdc=[],[],[],[]
for k in range(len(df)):
  datet.append(dt(df['year'][k],df['mth'][k],df['day'][k],df['hr_gmt'][k],df['mn'][k]))# creates a datetime
  hours.append(df['time_hours'][k])#*24)  changed this on 21 Nov 2019 because we do NOT want to multiply by 24 changed "days" to "hours"
  
  if k>len(already_calculated_depth_ngdc)-1: # only look for ngdc depth if this case if recent
    depth_ngdc=get_depth(df['lon'][k],df['lat'][k],mindist_allowed)
  else:
    depth_ngdc=already_calculated_depth_ngdc[k] # here we are saving the time of calculating again
  
  #depth_ngdc=get_depth(df['lon'][k],df['lat'][k],mindist_allowed)
  save_depth_ngdc.append(depth_ngdc)# gets historical record of bottom depth from NGDC database and sets = nan when > mindist_allowed exceeds
  #print (k,df['lon'][k],df['lat'][k],depth_ngdc)
  if gps_compare_JiM(df['lat'][k],df['lon'][k],min_miles_from_dock)=='yes': # this means it is near a dock
    flag.append(1)
  elif (df['mean_temp'][k]<temp_ok[0]) or (df['mean_temp'][k]>temp_ok[1]):  # this means bad temps
    flag.append(2)
  elif (df['depth'][k]<depth_ok[0]) or (df['depth'][k]>depth_ok[1]):        # this means bad depths
    flag.append(3)
  elif (abs(abs(df['depth'][k])-abs(depth_ngdc)))/df['depth'][k]>fraction_depth_error:
    #elif abs(df['depth'][k]-depth_ngdc)/depth_ngdc>fraction_depth_error:      # this means obs bottom depth very different from NGDC
    #print ('depth  '+str(df['depth'][k])+'depthabs'+str(abs(abs(df['depth'][k])-abs(depth_ngdc))))
    if abs(df['depth'][k])>50 or abs(df['depth'][k])<8: #flag 4 only apply on > 50 m
        flag.append(4)
    else:
        flag.append(0)
  elif (df['lat'][k]>47.) or (df['lat'][k]<30.) or (df['lon'][k]>-60.) or (df['lon'][k]<-80.): # this means it is not on the NE coast (added this 5/14/2020)
    flag.append(5)
  else:
    flag.append(0)# good data
#print (str(sum(num==1 for num in flag))+' hauls near dock')1
#print (str(sum(num==2 for num in flag))+' hauls with bad temp data')
#print (str(sum(num==3 for num in flag))+' hauls with depth out of acceptable range = ',depth_ok,' meters')
#print (str(sum(num==4 for num in flag))+' hauls with depth not within ',fraction_depth_error,' of NGDC depth')
#print (str(len(flag))+' total hauls')
df['datet']=datet
df['flag']=flag
df['hours']=hours# number of hours hauled
dfnew=df[['vessel','datet','lat','lon','depth','depth_range','hours','mean_temp','std_temp','flag']]
dfnew.to_csv('/var/www/vhosts/emolt.org/httpdocs/emoltdata/emolt_QCed.csv')
dfgood=dfnew[dfnew['flag']==0] # restrict to good data only

dfgood.to_csv('/var/www/vhosts/emolt.org/httpdocs/emoltdata/emolt_QCed_good.csv')# added this in Oct 2019 for NCEI folks
if len(save_depth_ngdc)!=0: # this was required for times where emolt.dat is empty and nothing is saved
  np.save('/var/www/vhosts/emolt.org/huanxin_ftp/weekly_project/result/already_calculated_depth_ngdc.npy',save_depth_ngdc)
