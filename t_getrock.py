#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Jan 22 15:05:45 2020
get rockblock data from studentdrifters.org, and save them.

 #need to modify function read_codes() inputfile1 ,path1='/home/hxu/Downloads/'  to your local path
@author: hxu
"""

from matplotlib.dates import date2num
import time
import pysftp
import os
import sys
import subprocess
from dateutil import parser
import glob
import json
import datetime
import numpy as np
import urllib
from dateutil import parser
'''
def read_codes(): #need to modify inputfile1 ,path1='/home/hxu/Downloads/'  to your local path
      # get id,depth from /data5/jmanning/drift/codes.dat, need to change the path1
      inputfile1="codes_temp.dat"
      #path1="/net/data5/jmanning/drift/"
      path1='/var/www/vhosts/emolt.org/huanxin_ftp/'
      #path1="/var/www/vhosts/studentdrifters.org/httpdocs/posthuanxin/"
      f1=open(path1+inputfile1,'r')
      esn,id,depth,vessel_names,form=[],[],[],[],[]
      for line in f1:
      	  esn.append(line.split()[0])
      	  id.append(line.split()[1])
          depth.append(line.split()[2])
          vessel_names.append(line.split()[3])
          form.append(line.split()[-1])
      return esn,id,depth,vessel_names,form
'''
def read_codes():
  # get id,depth from /data5/jmanning/drift/codes_temp.dat
  inputfile1="codes_temp.dat"
  path1="/net/data5/jmanning/drift/"
  path1="/var/www/vhosts/emolt.org/huanxin_ftp/"
  #path1='/home/hxu/Downloads/'
  
  f1=open(path1+inputfile1,'r')
  esn,id,depth,form,vessel_names=[],[],[],[],[]
  for line in f1:
    esn.append(line.split(',')[0])
    id.append(line.split(',')[1])
    depth.append(line.split(',')[2])
    vessel_names.append(line.split(',')[3])
    form.append(line.split(',')[-1])
  return esn,id,depth,vessel_names,form
################################################
#link='https://emolt.org/posthuanxin/rockemolt.dat' # here is the address where you download rockblock data
#f_output=open('ap3_'+  str(datetime.datetime.now())[:16]+'.dat','w') #open a ouput file,change paths if needed
f_output=open('/var/www/vhosts/emolt.org/httpdocs/posthuanxin/test_rock_emolt.dat','w')
daily_output=open('/var/www/vhosts/emolt.org/httpdocs/emoltdata/test_daily_emolt.dat','w')
#f_output=open('/var/www/vhosts/emolt.org/httpdocs/rock_emolt.dat','a+')
################################################
esn2, ide,depth,vessel_names,form=read_codes()# get the id,depth from /data5/jmanning/drift/codes.dat,
esn,dates,lat,lon,battery,data_send,meandepth,rangedepth,timelen,meantemp,sdeviatemp=[],[],[],[],[],[],[],[],[],[],[], 
date_time,year,month,day,hour,minute,second,yearday=[],[],[],[],[],[],[],[] 
#esn2, ide,depth=read_codes()
rockdata=[]

#from urllib.request import urlopen
#f = urlopen(link)
#f=open('/var/www/vhosts/emolt.org/httpdocs/posthuanxin/rockemolt.dat','r')
f=open('/var/www/vhosts/emolt.org/httpdocs/posthuanxin/test_rockemolt.dat','r')
myfile = f.read()
#print(myfile)
lines=myfile.splitlines()# put everyling into a list
datas,esn,transmit_time=[],[],[]

for i in range(len(lines)):
    try:
            
            lat1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[0])
            datas1=bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode()
            
            esn1=str(lines[i]).split('imei=')[1].split('&')[0]
            
            transmit_time1=str(lines[i]).split('transmit_time=')[1].split('&iridium')[0]
            dates1=transmit_time1[0:8]+transmit_time1[11:13]+transmit_time1[16:18]+transmit_time1[21:23]
            date_time1=datetime.datetime.strptime(dates1,"%y-%m-%d%H%M%S" )
            index_idn1=(np.where(esn1[-6:]==np.array(ide)))[0][0]
            form1=form[index_idn1]
            #print (form1)
            lon1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[1])
            meandepth1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][0:3]) 
            rangedepth1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][3:6])
            #print ('2')
            if 'u' in datas1:
                
                timelen1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][6:11])/60
                meantemp1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][11:15])/100
                sdeviatemp1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][15:19])/100
                
                #date_time1=datetime.datetime.strptime(dates1,"%y-%m-%d%H%M%S" )
                year1=str(date_time1.year)
                month1=str(date_time1.month)
                day1=str(date_time1.day)
                hour1=str(date_time1.hour)
                minute1=str(date_time1.minute)
                second1=str(date_time1.second)
                yearday1=int(date_time1.strftime('%j'))+date_time1.hour/24+date_time1.minute/24./60. # get yearday
        		#print (dates1)
        		
                lat.append(lat1)
                datas.append(datas1) # format byte data to string and add to "datas" list
                esn.append(esn1)
                transmit_time.append(transmit_time1)
        
        
                lon.append(lon1)
                meandepth.append(meandepth1)   
                rangedepth.append(rangedepth1)
                timelen.append(timelen1)
                meantemp.append(meantemp1)
                sdeviatemp.append(sdeviatemp1)
                dates.append(dates1)
                date_time.append(date_time1)
                year.append(str(date_time1.year))
                month.append(str(date_time1.month))
                day.append(str(date_time1.day))
                hour.append(str(date_time1.hour))
                minute.append(str(date_time1.minute))
                second.append(str(date_time1.second))
                yearday.append(int(date_time1.strftime('%j'))-1+date_time1.hour/24+date_time1.minute/24./60.) # get yearday
        		#yearday.append(int(date_time1.strftime('%j'))-1+date_time1.hour/24+date_time1.minute/24./60.)
            else:    
                if 'm' in form[index_idn1]:
                    timelen1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][6:9])/60
                    #print (1)
                else:
                    timelen1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][6:9])
                meantemp1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][9:13])/100
                sdeviatemp1=float(bytearray.fromhex(str(lines[i]).split('data=')[1].split("'")[0]).decode().split(',')[2][13:17])/100
        		
                #date_time1=datetime.datetime.strptime(dates1,"%y-%m-%d%H%M%S" )
                year1=str(date_time1.year)
                month1=str(date_time1.month)
                day1=str(date_time1.day)
                hour1=str(date_time1.hour)
                minute1=str(date_time1.minute)
                second1=str(date_time1.second)
                yearday1=int(date_time1.strftime('%j'))+date_time1.hour/24+date_time1.minute/24./60. # get yearday
        		#print (dates1)
        		
                lat.append(lat1%100/60+int(lat1/100))
                datas.append(datas1) # format byte data to string and add to "datas" list
                esn.append(esn1)
                transmit_time.append(transmit_time1)
        
        
                lon.append(-(lon1%100/60+int(lon1/100)))
                meandepth.append(meandepth1)   
                rangedepth.append(rangedepth1)
                timelen.append(timelen1)
                meantemp.append(meantemp1)
                sdeviatemp.append(sdeviatemp1)
                dates.append(dates1)
                date_time.append(date_time1)
                year.append(str(date_time1.year))
                month.append(str(date_time1.month))
                day.append(str(date_time1.day))
                hour.append(str(date_time1.hour))
                minute.append(str(date_time1.minute))
                second.append(str(date_time1.second))
                yearday.append(int(date_time1.strftime('%j'))-1+date_time1.hour/24+date_time1.minute/24./60.) # get yearday
        		#yearday.append(int(date_time1.strftime('%j'))-1+date_time1.hour/24+date_time1.minute/24./60.)
    except:        
        if datas1.split(',')[-1][-4:]=='0000':
            try:
                
                index_idn1=(np.where(esn1[-6:]==np.array(ide)))[0][0]
            except:
                print (datas1)
                print ('please update codes_temp.dat')
                break
            vessel_name=vessel_names[index_idn1]
            daily_output.write(str(vessel_name).rjust(10)+" "+str(datetime.datetime.strftime(date_time1, "%Y-%m-%d %H:%M:%S")).rjust(20)+' '+("%10.5f") %(lat1%100/60+int(lat1/100))+' '+("%10.5f") %-(lon1%100/60+int(lon1/100))+"\n")
        elif datas1.split(',')[-1][-4:]=='1111':
            try:
                
                index_idn1=(np.where(esn1[-6:]==np.array(ide)))[0][0]
            except:
                print (datas1)
                print ('please update codes_temp.dat')
                break
            vessel_name=vessel_names[index_idn1]
            daily_output.write(str(vessel_name).rjust(10)+" "+str(datetime.datetime.strftime(date_time1, "%Y-%m-%d %H:%M:%S")).rjust(20)+' '+("%10.5f") %(lat1)+' '+("%10.5f") %(lon1)+"\n")
        else:    
            continue
            


			
			


index_idn1=[]
    
for o in range(len(dates)): # to save the file
    if meantemp[o]<30:
          #print (dates[o])
          index_idn1=(np.where(esn[o][-6:]==np.array(ide)))[0][0] # index of the codes_temp file
          id_idn1=esn2[index_idn1] # where is the consecutive time this unit was used
          depth_idn1=-1.0*float(depth[index_idn1]) # make depth negative
          if form[index_idn1]=='m':
              timelen[o]=timelen[o]/60.
              
          #f_output=open('ap3_'+  str(datetime.datetime.now())[:16]+'.dat', 'w')
          f_output.write(str(id_idn1).rjust(10)+" "+str(int(esn[o][-7:])).rjust(7)+ " "+str(month[o]).rjust(2)+ " " +
                  str(day[o]).rjust(2)+" " +str(hour[o]).rjust(3)+ " " +str(minute[o]).rjust(3)+ " " )
          f_output.write(("%10.7f") %(yearday[o]))
          #f_output.write(" "+str(lon).rjust(10)+' '+str(lat).rjust(10)+ " " +str(float(depth_idn1)).rjust(4)+ " "
          #        +str(np.nan))
          f_output.write(" "+("%10.5f") %(lon[o])+' '+("%10.5f") %(lat[o])+' '+str(float(depth_idn1)).rjust(4)+ " "+'nan')
          #f_output.write(" "+str(meandepth).rjust(10)+' '+str(rangedepth).rjust(10)+' '+str(len_day).rjust(10)+  " " +str(mean_temp).rjust(4)+ " "
          #        +str(sdevia_temp)+'\n')            
          f_output.write(" "+str(meandepth[o]).rjust(10)+' '+str(rangedepth[o]).rjust(10)+''+("%6.1f") %(timelen[o])+  "" +("%6.2f") %(meantemp[o])+ " "
                  +("%6.2f") %(sdeviatemp[o])+("%6.0f") %(int(year[o]))+'\n')  
daily_output.close()          
f_output.close()          
#os.system('cat -n /var/www/vhosts/emolt.org/httpdocs/posthuanxin/rock_emolt.dat  | sort -uk2 | sort -nk1 | cut -f2- > /var/www/vhosts/emolt.org/httpdocs/posthuanxin/rock_emolt2.dat')
