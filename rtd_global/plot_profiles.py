#!/usr/bin/env python
# coding: utf-8

import numpy as np
import matplotlib.pyplot as plt
import time
import pandas as pd
from datetime import timedelta, datetime
import os
import sys
sys.path.insert(1,'/home/pi/Desktop/')
import setup_rtd


# from pandas.plotting import register_matplotlib_converters


class Plotting(object):
    def __init__(self, profile):
        self.df = profile
        self.path = '/'.join(setup_rtd.parameters['path'].split('/')[:3]) + '/'
        if len(self.df) > 0:
            if setup_rtd.parameters['tem_unit'] == 'Fahrenheit':
                self.df['TEMPERATURE'] = self.df['TEMPERATURE'] * 1.8 + 32
            if setup_rtd.parameters['depth_unit'] == 'Fathoms':
                self.df['PRESSURE'] = self.df['PRESSURE'] * 0.546807
            self.df['DATETIME'] += timedelta(hours=setup_rtd.parameters['local_time'])
            self.filename = self.df.iloc[-1]['DATETIME'].strftime('%y-%m-%d %H%M')
            try:
                self.plot_profile()
            except:
                pass
            try:
                self.plot_up_down()
            except:
                pass
            if setup_rtd.parameters['tem_unit'] == 'Fahrenheit':
                self.df['TEMPERATURE'] = (self.df['TEMPERATURE'] - 32) / 1.8
            if setup_rtd.parameters['depth_unit'] == 'Fathoms':
                self.df['PRESSURE'] = self.df['PRESSURE'] / 0.546807
            self.df['DATETIME'] -= timedelta(hours=setup_rtd.parameters['local_time'])
        # register_matplotlib_converters()
    '''
    def p_create_pic(self):

      tit='Temperature and Depth'
      
      if not os.path.exists('/home/pi/Desktop/Profiles'):
        os.makedirs('/home/pi/Desktop/Profiles')

      if not os.path.exists(self.path+'merged/uploaded_files'):
        os.makedirs(self.path+'merged/uploaded_files')
      n=0  
      if 'r' in open('/home/pi/Desktop/mode.txt').read():
        file='control_file.txt'
        mode='real'
      else:
        file='test_control_file.txt'
        mode='test'
      print (1)
      try:
            files=[]
            files.extend(sorted(glob.glob('/home/pi/Desktop/towifi/*.csv')))
            
            if not os.path.exists('uploaded_files/mypicfile.dat'):
                open('uploaded_files/mypicfile.dat','w').close() 
            
            with open('uploaded_files/mypicfile.dat','r') as f:
                content = f.readlines()
                f.close()
            
            upfiles = [line.rstrip('\n') for line in open('uploaded_files/mypicfile.dat','r')]
            dif_data=list(set(files)-set(upfiles))
           
            if dif_data==[]:
                print  'Standby. When the program detects a probe haul, machine will reboot and show new data.'
                import time
                time.sleep(14)
                
                return
            

    ##################################
    ##################################
            dif_data.sort(key=os.path.getmtime)
            print (2)
            for fn in dif_data:          
            
                fn2=fn
                              
                if not os.path.exists('/home/pi/Desktop/Pictures/'+fn.split('/')[-1].split('_')[2]):
                    os.makedirs('/home/pi/Desktop/Pictures/'+fn.split('/')[-1].split('_')[2])
                df=pd.read_csv(fn,sep=',',skiprows=8,parse_dates={'datet':[1]},index_col='datet',date_parser=parse2)#creat a new Datetimeindex
                if mode=='real':
                    df=df.ix[(df['Depth (m)']>0.85*mean(df['Depth (m)']))]
                    df=df.ix[3:-2] # delete this line if cannot get plot
                    if len(df)>1000:
                        df=df.ix[5:-5]
                        df=df.iloc[::(len(df)/960+1),:] #Plot at most 1000 data
                else:
                    if len(df)>1000:
                        df=df.iloc[::(len(df)/960+1),:]
                df2=df
                df2['Depth (m)']=[x*(-0.5468) for x in df2['Depth (m)'].values]
                #change to -0.5468 if you want to show negtive depth on Pic
                if len(df2)<5:
                    continue
                print (3)
                meantemp=round(np.mean(df['Temperature (C)']),2)
                fig=plt.figure(figsize=(7,4))#figsize?
                ax1=fig.add_subplot(211)
                ax2=fig.add_subplot(212)
                time_df2=gmt_to_eastern(df2.index)
                time_df=gmt_to_eastern(df.index)
     
                ax1.plot(time_df,df['Temperature (C)']*1.8+32,'b',)
                #ax1.set_xlim(time_df[1],time_df[-2])
                #ax1.set_ylim(np.nanmin(df['Temperature (C)'].values)*1.8+30,np.nanmax(df['Temperature (C)'].values)*1.8+36)
                ax1.set_ylabel('Temperature (Fahrenheit)')
                ax1.legend(['temp','in the water'])
                
                try:    
                        if max(df.index)-min(df.index)>Timedelta('0 days 04:00:00'):
                            ax1.xaxis.set_major_locator(dates.DateLocator(interval=(max(df.index)-min(df.index)).seconds/3600/12))# for hourly plot
                            ax2.xaxis.set_major_locator(dates.DateLocator(interval=(max(df.index)-min(df.index)).seconds/3600/12))# for hourly plot
                        else:
                            ax1.xaxis.set_major_locator(dates.DateLocator(interval=(max(df.index)-min(df.index)).seconds/3600/4))# for hourly plot
                            ax2.xaxis.set_major_locator(dates.DateLocator(interval=(max(df.index)-min(df.index)).seconds/3600/4))# for hourly plot
                except:
                    print ' '
                
                clim=getclim()# extracts climatological values at this place and yearday
                
                if isnan(clim):
                    txt='mean temperature ='+str(round(c2f(meantemp),1))+'F (No Climatology here.)'
                else:    
                    txt='mean temperature ='+str(round(c2f(meantemp),1))+'F Climatology ='+str(round(c2f(clim),1))+'F'
                ax1.text(0.95, 0.01,txt,
                            verticalalignment='bottom', horizontalalignment='right',
                            transform=ax1.transAxes,
                            color='red', fontsize=14)
                
                ax1.grid()
                ax12=ax1.twinx()
                ax12.set_title(tit)
                #ax12.set_ylabel('Fahrenheit')
                ax12.set_ylabel('Temperature (Celius)')
                #ax12.set_xlabel('')
                ax12.set_ylim(np.nanmin(df['Temperature (C)'].values),np.nanmax(df['Temperature (C)'].values)+0.01)

                ax2.plot(time_df2,df2['Depth (m)'],'b',label='Depth',color='green')
                ax2.legend()
                ax2.invert_yaxis()
                ax2.set_ylabel('Depth(Fathom)')
                ax2.set_ylim(np.nanmin(df2['Depth (m)'].values)*1.05,np.nanmax(df2['Depth (m)'].values)*0.95)
                #ax2.set_xlim(time_df2[1],time_df2[-2])
                ax2.yaxis.set_major_formatter(ScalarFormatter(useOffset=False))
                ax2.grid()
                
                ax22=ax2.twinx()
                ax22.set_ylabel('Depth(feet)')
                ax22.set_ylim(round(np.nanmax(df2['Depth (m)'].values)*6*0.95,1),round(np.nanmin(df2['Depth (m)'].values)*6*1.05,1))        
                ax22.invert_yaxis()

                plt.gcf().autofmt_xdate()    
                ax2.set_xlabel('TIME '+time_df[0].astimezone(pytz.timezone('US/Eastern')).strftime('%m/%d/%Y %H:%M:%S')+' - '+time_df[-1].astimezone(pytz.timezone('US/Eastern')).strftime('%m/%d/%Y %H:%M:%S'))
                plt.savefig('/home/pi/Desktop/Pictures/'+fn.split('/')[-1].split('_')[2]+'/'+fn.split('/')[-1].split('_')[-1].split('.')[0]+'.png')
                plt.close()

            a=open('uploaded_files/mypicfile.dat','r').close()
            
            a=open('uploaded_files/mypicfile.dat','a+')
            
            [a.writelines(i+'\n') for i in dif_data]
            a.close()

            print 'New data successfully downloaded. Plot will appear.'
            return 
       
      except:
          print 'the new csv file cannot be plotted, skip it'
          a=open('uploaded_files/mypicfile.dat','a+')
            
          [a.writelines(i+'\n') for i in dif_data]
          a.close()
          return
    '''                        
    def plot_profile(self):
        try:
            os.mkdir(self.path + 'Desktop/Profiles/' + self.filename)
        except:
            pass
        fig, ax_c = plt.subplots(figsize=(15, 9))
        #print (1)
        lns1 = ax_c.plot(self.df['DATETIME'], self.df['PRESSURE'], '-', color='deepskyblue', label="pressure",
                         zorder=20,
                         linewidth=10)

        ax_c.set_ylabel(setup_rtd.parameters['depth_unit'], fontsize=20)
        ax_c.set_xlabel('Local time', fontsize=20)

        ax_c.set_xlim(min(self.df['DATETIME']) - timedelta(minutes=5),
                      max(self.df['DATETIME']) + timedelta(minutes=5))  # limit the plot to logged data
        ax_c.set_ylim(min(self.df['PRESSURE']) - 0.5, max(self.df['PRESSURE']) + 0.5)

        plt.tick_params(axis='both', labelsize=15)

        ax_f = ax_c.twinx()
        #print (2)
        lns2 = ax_f.plot(self.df['DATETIME'], self.df['TEMPERATURE'], '--', color='r', label="temperature", zorder=10,
                         linewidth=10)

        ax_f.set_xlim(min(self.df['DATETIME']) - timedelta(minutes=5),
                      max(self.df['DATETIME']) + timedelta(minutes=5))  # limit the plot to logged data
        ax_f.set_ylim(min(self.df['TEMPERATURE']) - 0.5, max(self.df['TEMPERATURE']) + 0.5)

        ax_c.set_ylim(ax_c.get_ylim()[::-1])

        plt.title('{vessel} data'.format(vessel=setup_rtd.metadata['vessel_name']), fontsize=20)

        ax_f.set_ylabel(setup_rtd.parameters['tem_unit'], fontsize=20)

        fig.autofmt_xdate()
        #print (3)
        lns = lns1 + lns2
        labs = [l.get_label() for l in lns]
        ax_c.legend(lns, labs, fontsize=15)

        plt.tick_params(axis='both', labelsize='large')

        plt.savefig(self.path + 'Desktop/Profiles/' + self.filename + '/' + self.filename + '_profile.png')

        plt.close()

    def plot_up_down(self):
        df_down = self.df[self.df['type'] == 2].reset_index(drop=True)
        df_up = self.df[self.df['type'] == 1][::-1].reset_index(drop=True)

        # plot discrepancy temperatures over time
        fig, ax = plt.subplots(figsize=(12, 12))

        mintem_row = df_down.loc[df_down['TEMPERATURE'].idxmin()]
        mintem = mintem_row['TEMPERATURE']
        dep_mintem = mintem_row['PRESSURE']

        # get the row of max value
        maxtem_row = df_down.loc[df_down['TEMPERATURE'].idxmax()]
        maxtem = maxtem_row['TEMPERATURE']
        dep_maxtem = maxtem_row['PRESSURE']

        plt.plot(df_down['TEMPERATURE'], df_down['PRESSURE'], 'green', label='down profile', alpha=0.5, linewidth=10,
                 zorder=1)

        tem = plt.scatter(self.df['TEMPERATURE'], self.df['PRESSURE'], c=self.df['TEMPERATURE'],
                          cmap='coolwarm', label='temperature', linewidth=5, zorder=3)

        # min_tem = plt.scatter(mintem, -dep_mintem, c='blue')
        plt.annotate(round(mintem, 1), (mintem, dep_mintem), fontsize=20, weight='bold')
        # max_tem = plt.scatter(maxtem, -dep_maxtem, c='green')
        plt.annotate(round(maxtem, 1), (maxtem, dep_maxtem), fontsize=20, weight='bold')

        mintem_row1 = df_up.loc[df_up['TEMPERATURE'].idxmin()]
        mintem1 = mintem_row1['TEMPERATURE']
        dep_mintem1 = mintem_row1['PRESSURE']

        # get the row of max value
        maxtem_row1 = df_up.loc[df_up['TEMPERATURE'].idxmax()]
        maxtem1 = maxtem_row1['TEMPERATURE']
        dep_maxtem1 = maxtem_row1['PRESSURE']

        plt.plot(df_up['TEMPERATURE'], df_up['PRESSURE'], 'purple', label='up profile', alpha=0.5, linewidth=10,
                 zorder=1)
        plt.annotate(round(mintem1, 1), (mintem1, dep_mintem1), fontsize=20, weight='bold')
        plt.annotate(round(maxtem1, 1), (maxtem1, dep_maxtem1), fontsize=20, weight='bold')

        ax.set_xlabel("Temperature ({tem_unit})".format(tem_unit=setup_rtd.parameters['tem_unit']), fontsize=20)
        ax.set_ylabel("Depth ({depth_unit})".format(depth_unit=setup_rtd.parameters['depth_unit']), fontsize=20)

        ax.set_ylim(ax.get_ylim()[::-1])

        plt.title("Profiles temperature vs pressure comparison on {date}".format(date=self.df['DATETIME'].iloc[-1]), fontsize=20)
        plt.legend(fontsize=15)

        cbar = plt.colorbar(tem, shrink=0.5, aspect=20)

        cbar.ax.tick_params(labelsize='large')

        plt.tick_params(axis='both', labelsize=15)

        plt.savefig(self.path + 'Desktop/Profiles/' + self.filename + '/' + self.filename + '_up_down.png')

        plt.close()



