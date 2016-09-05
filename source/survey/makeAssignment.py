# grantBonus.py
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
# This script sets a qualification on MTurk using the assignQuali...sh. The MTur
# k command line tools require that JAVA_HOME is set to the location of Java on
# your machine.  On Unix, this can be done using the following command:
#    export JAVA_HOME=/usr

import time
import os
import sys
from sys import argv
script, fname = argv

#-------------------------------------------------------------------------------
#--- (1) locations of files and system commands
#-------------------------------------------------------------------------------
cloc = "/home/damian/computacion/MTurk/aws-mturk-clt-1.3.1/bin/"
floc = "/home/damian/investigacion/2015/birthQuarter/data/survey/conjoint/"

workers = open(floc+fname+'.csv', 'r')

#-------------------------------------------------------------------------------
#--- (2) Assign condition
#-------------------------------------------------------------------------------
Margs = " -qualtypeid 3YZYG5XLRWDVV9NJZXC2XW9L1PFYHS -score 100 -donotnotify"

workers = open(floc+fname+'.csv', 'r')

output  = open(floc+fname+'madeCondition.csv','w')
output.write('Worker,date,time\n')
os.chdir(cloc)
for i,line in enumerate(workers):
    if i>0:
        worker = line.replace("\n","")
        #NOTE: to test this script, replace the following os.system call with print.
        os.system('./assignQualification.sh -workerid '+ worker + Margs)
        ptime = time.strftime("%H:%M:%S")
        pdate = time.strftime("%d/%m/%Y")
        output.write(worker+','+pdate+','+ptime+'\n')
        
output.close()

#-------------------------------------------------------------------------------
#--- (5) End
#-------------------------------------------------------------------------------
print "The script has now assigned all conditions and saved a record of these."
print "The final account balance will be displayed below."
value=os.system("./getBalance.sh")
