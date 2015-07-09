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

states = ['01 001 Alabama',
          '04 002 Arizona',
          '05 003 Arkansas',
          '06 004 California',
          '08 005 Colorado',
          '09 006 Connecticut',
          '10 007 Delaware',
          '12 008 Florida',
          '13 009 Georgia',
          '16 010 Idaho',
          '17 011 Illinois',
          '18 012 Indiana',
          '19 013 Iowa',
          '20 014 Kansas',
          '21 015 Kentucky',
          '22 016 Louisiana',
          '23 017 Maine',
          '24 018 Maryland',
          '25 019 Massachusetts',
          '26 020 Michigan',
          '27 021 Minnesota',
          '28 022 Mississippi',
          '29 023 Missouri',
          '30 024 Montana',
          '31 025 Nebraska',
          '32 026 Nevada',
          '33 027 New Hampshire',
          '34 028 New Jersey',
          '35 029 New Mexico',
          '36 030 New York',
          '37 031 North Carolina',
          '38 032 North Dakota',
          '39 033 Ohio',
          '40 034 Oklahoma',
          '41 035 Oregon',
          '42 036 Pennsylvania',
          '44 037 Rhode Island',
          '45 038 South Carolina',
          '46 039 South Dakota',
          '47 040 Tennessee',
          '48 041 Texas',
          '49 042 Utah',
          '50 043 Vermont',
          '51 044 Virginia',
          '53 045 Washington',
          '54 046 West Virginia',
          '55 047 Wisconsin',
          '56 048 Wyoming',
          '02 050 Alaska',
          '99 110 National']

Sfiles  = ['climdiv-tmpcst-v1.0.0-20150706','climdiv-tminst-v1.0.0-20150706',
           'climdiv-tmaxst-v1.0.0-20150706']
outdat  = open(DAT + 'usaWeather.txt','w')
outdat.write('state;FIPS;year;month;type;temp\n')

#-------------------------------------------------------------------------------
#--- (1) Read in from web
#-------------------------------------------------------------------------------
for f in ['tmpcst','tminst','tmaxst']:
    print f
    #data = urllib2.urlopen(WEB+'climdiv-'+f+datVer).read()
    #outfile  = open(OUT + f, 'w')
    #outfile.write(data)
    #outfile.close()


#-------------------------------------------------------------------------------
#--- (2) Write to one line per state*year*month*type
#-------------------------------------------------------------------------------
for s in states: 
    FIPS = s[0:2]
    StID = s[3:6]
    name = s[7:]


    for f in ['tmpcst','tminst','tmaxst']:
        data = open(OUT + f, 'r').readlines()

        for line in data:
            dataID = line[0:3]
            if StID == dataID:
                for year in range(1895,2015):
                    dyear = line[6:10]
                    if str(year) == dyear:
                        temps = line[12:-3]
                        temp = temps.split('  ')
                        for mn,t in enumerate(temp):
                            mn = mn+1
                            
                            outdat.write(name+';'+FIPS+';'+dyear)
                            outdat.write(';'+str(mn)+';'+f+';'+t+'\n')

outdat.close()
