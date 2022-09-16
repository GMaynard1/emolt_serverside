metadata = {'time_range': 1,
            'Fathom': .1,
            'transmitter': 'yes',
            'mac_addr': ['C9:3C:F8:37:E9:6A','C9:08:0F:5F:13:27','D6:EB:6B:13:FA:96'],
            'moana_SN': '0113',
            'gear_type': 'mobile',
            'vessel_num': 99,
            'vessel_name': 'Default_setup',
            'tilt': 'no'}

parameters = {'path': '/home/pi/rtd_global/',
              'sensor_type': ['Moana'],
              'time_diff_nke': 0,
              'tem_unit': 'Fahrenheit',
              'depth_unit': 'Fathoms',
              'local_time': -4 }



############################################################################
########################### OPTIONS ########################################
############################################################################
#Most important: you only need to change First part: metadata
# format as below
#           'mac_addr': ['CF:D4:F1:9D:8D:A8','ED:E8:8C:F6:86:C6','C1:07:7B:6E:C6:16'],
#            'moana_SN': '0113',
#            'gear_type': 'mobile',
#            'vessel_num': 99,
#            'vessel_name': 'Default_setup',


# path: use always '/home/pi/rtd_global/'
# sensor_type: 'Bluetooth'/'WiFi'/'both'
# time_diff_nke: if you have NKE sensor, difference between the sensor timestamp and UTC
# vessel_name: provided by BDC
# Lowell_SN: write the Lowell sensor MAC address
# gear_type: 'Mobile'/'Fixed'
# tem_unit: temperature unit to plot
# depth_unit: depth unit to plot
# local_time: local time to plot