# unemployScrape.py              damiancclarke             yyyy-mm-dd:2015-06-14
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This file scrapes USA weather data from the web, where it is stored as text f-
# iles by the National Centers for Environmental Information. It uses urllib2 f-
# rom python. This could be done using wget on Unix, but this Python version sh-
# ould port to other operating systems as well.  Files are stored by the NCEI as
# FTP, and then are parsed using the README at:
#
#   ftp://ftp.ncdc.noaa.gov/pub/data/cirs/climdiv/state-readme.txt
#
# See this README and the full list of FTP files at:
#
#   ftp://ftp.ncdc.noaa.gov/pub/data/cirs/climdiv/
#

import os
import urllib2
from urllib2 import urlopen, URLError, HTTPError
import re

OUT    = '/home/damiancclarke/database/USWeather/'
WEB    = 'ftp://ftp.ncdc.noaa.gov/pub/data/cirs/climdiv/'
DAT    = '/home/damiancclarke/investigacion/2015/birthQuarter/data/weather/'
datVer = '-v1.0.0-20150706'

states = ['001 Alabama',
          '002 Arizona',
          '003 Arkansas',
          '004 California',
          '005 Colorado',
          '006 Connecticut',
          '007 Delaware',
          '008 Florida',
          '009 Georgia',
          '010 Idaho',
          '011 Illinois',
          '012 Indiana',
          '013 Iowa',
          '014 Kansas',
          '015 Kentucky',
          '016 Louisiana',
          '017 Maine',
          '018 Maryland',
          '019 Massachusetts',
          '020 Michigan',
          '021 Minnesota',
          '022 Mississippi',
          '023 Missouri',
          '024 Montana',
          '025 Nebraska',
          '026 Nevada',
          '027 New Hampshire',
          '028 New Jersey',
          '029 New Mexico',
          '030 New York',
          '031 North Carolina',
          '032 North Dakota',
          '033 Ohio',
          '034 Oklahoma',
          '035 Oregon',
          '036 Pennsylvania',
          '037 Rhode Island',
          '038 South Carolina',
          '039 South Dakota',
          '040 Tennessee',
          '041 Texas',
          '042 Utah',
          '043 Vermont',
          '044 Virginia',
          '045 Washington',
          '046 West Virginia',
          '047 Wisconsin',
          '048 Wyoming',
          '050 Alaska']

Sfiles  = ['climdiv-tmpcst-v1.0.0-20150706','climdiv-tminst-v1.0.0-20150706',
           'climdiv-tmaxst-v1.0.0-20150706']
outdat  = open(DAT + 'usaWeather.txt','w')
outdat.write('state;statenum;year;month;ave;min;max\n')


for f in ['tmpcst','tminst','tmaxst']:
    print f
    data = urllib2.urlopen(WEB+'climdiv-'+f+datVer).read()
    outfile  = open(OUT + f, 'w')
    outfile.write(data)
    outfile.close()

