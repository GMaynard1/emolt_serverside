# -*- coding: utf-8 -*-
"""
Created on Thu Jun 23 13:19:11 2022

@author: James.manning
"""
import time
import ftplib
import netCDF4
import numpy as np
import pandas as pd

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

def get_depth(loni,lati,mindist_allowed):
    # routine to get depth (meters) using vol1 from NGDC
  try:  
    if lati>=40.:
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
      depth=nc['z'][yi,xi]
  except:
    url='https://coastwatch.pfeg.noaa.gov/erddap/griddap/srtm30plus_LonPM180.csv?z%5B(33.):1:(47.)%5D%5B(-78.):1:(-62.)%5D'  
    df=pd.read_csv(url)
    lon=df['longitude'].values[1:].astype(np.float)
    lat=df['latitude'].values[1:].astype(np.float)
    i= nearlonlat(lon,lat,loni,lati)
    depth=df['z'].values[i]
  return depth#,min_dist

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

def nearlonlat(lon,lat,lonp,latp): # needed for the next function get_FVCOM_bottom_temp
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
