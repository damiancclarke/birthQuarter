# unemployScrape.py              damiancclarke             yyyy-mm-dd:2015-06-14
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This file scrapes USA unemployment data from the web, where it is loaded as t-
# ext files by the Bureau of Labor Statistics. It uses urllib2 from python. This
# could be done using wget on Unix, but this Python version should port to other
# operating systems as well.
#
#   http://download.bls.gov/pub/time.series/la/
#

import os
import urllib2
from urllib2 import urlopen, URLError, HTTPError
import re

OUT = '/home/damiancclarke/database/BLS/'
WEB = 'http://download.bls.gov/pub/time.series/la/'
DAT = '/home/damiancclarke/investigacion/2015/birthQuarter/data/employ/'

states = ['la.data.10.Arkansas',
'la.data.11.California',
'la.data.12.Colorado',
'la.data.13.Connecticut',
'la.data.14.Delaware',
'la.data.15.DC',
'la.data.16.Florida',
'la.data.17.Georgia',
'la.data.18.Hawaii',
'la.data.19.Idaho',
'la.data.20.Illinois',
'la.data.21.Indiana',
'la.data.22.Iowa',
'la.data.23.Kansas',
'la.data.24.Kentucky',
'la.data.25.Louisiana',
'la.data.26.Maine',
'la.data.27.Maryland',
'la.data.28.Massachusetts',
'la.data.29.Michigan',
'la.data.30.Minnesota',
'la.data.31.Mississippi',
'la.data.32.Missouri',
'la.data.33.Montana',
'la.data.34.Nebraska',
'la.data.35.Nevada',
'la.data.36.NewHampshire',
'la.data.37.NewJersey',
'la.data.38.NewMexico',
'la.data.39.NewYork',
'la.data.40.NorthCarolina',
'la.data.41.NorthDakota',
'la.data.42.Ohio',
'la.data.43.Oklahoma',
'la.data.44.Oregon',
'la.data.45.Pennsylvania',
'la.data.46.PuertoRico',
'la.data.47.RhodeIsland',
'la.data.48.SouthCarolina',
'la.data.49.SouthDakota',
'la.data.50.Tennessee',
'la.data.51.Texas',
'la.data.52.Utah',
'la.data.53.Vermont',
'la.data.54.Virginia',
'la.data.56.Washington',
'la.data.57.WestVirginia',
'la.data.58.Wisconsin',
'la.data.59.Wyoming',
'la.data.7.Alabama',
'la.data.8.Alaska',
'la.data.9.Arizona']

indicator = ['LASST050000000000003',
'LASBS060000000000003',
'LASST080000000000003',
'LASST090000000000003',
'LASST100000000000003',
'LASST110000000000003',
'LASBS120000000000003',
'LASST130000000000003',
'LASST150000000000003',
'LASST160000000000003',
'LASST170000000000003',
'LASST180000000000003',
'LASST190000000000003',
'LASST200000000000003',
'LASST210000000000003',
'LASST220000000000003',
'LASST230000000000003',
'LASST240000000000003',
'LASST250000000000003',
'LASST260000000000003',
'LASST270000000000003',
'LASST280000000000003',
'LASST290000000000003',
'LASST300000000000003',
'LASST310000000000003',
'LASST320000000000003',
'LASST330000000000003',
'LASST340000000000003',
'LASST350000000000003',
'LASST360000000000003',
'LASST370000000000003',
'LASST380000000000003',
'LASST390000000000003',
'LASST400000000000003',
'LASST410000000000003',
'LASST420000000000003',
'LASST720000000000003',
'LASST440000000000003',
'LASST450000000000003',
'LASST460000000000003',
'LASST470000000000003',
'LASST480000000000003',
'LASST490000000000003',
'LASST500000000000003',
'LASST510000000000003',
'LASST530000000000003',
'LASST540000000000003',
'LASST550000000000003',
'LASST560000000000003',
'LASST010000000000003',
'LASST020000000000003',
'LASST040000000000003',
]

outdat  = open(DAT + 'unemployment.txt','w')
outdat.write('state;fips;series_id;year;period;value;notes')

for i,s in enumerate(states):
    sname = s.split('.')[-1]
    fips  = s.split('.')[-2]

    print sname + fips
    #data     = urllib2.urlopen(WEB+s).read()
    #outfile  = open(OUT + s, 'w')
    #outfile.write(data)
    #outfile.close()
    
    alldat  = open(OUT + s, 'r').readlines()
    match   = indicator[i]

    for line in alldat:
        if match in line:
            line = re.sub('\s+', ';',line)
            print line
            outdat.write(sname+';'+fips+';'+line+'\n')

outdat.close()
