# grantBonus.py
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
# This script pays bonuses on MTurk.  There is error capture to ensure that bonu
# ses aren't too large, and only with confirmation will the script run. The MTur
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
floc = "/home/damian/investigacion/2015/birthQuarter/MTurk/main/round1/"

workers = open(floc+fname+'.csv', 'r')

#-------------------------------------------------------------------------------
#--- (2) Test general script details
#-------------------------------------------------------------------------------
totalBonus = 0
maxBonus   = 0
minBonus   = 100

for i,line in enumerate(workers):
    if i>0:
        bonline = float(line.split(",")[2])
        totalBonus = totalBonus + bonline
        if bonline > maxBonus:
            maxBonus = bonline
        if bonline < minBonus:
            minBonus = bonline
    N=i

ave = totalBonus/N
print "Total Bonus is %f." %totalBonus
print "Maximum Bonus is %f." %maxBonus
print "Minimum Bonus is %f." %minBonus

if maxBonus>=1:
    print "This script is not authorised to pay a bonus of $1 or more. Exiting"
    sys.exit()

os.chdir(cloc)
value=os.system("./getBalance.sh")


#-------------------------------------------------------------------------------
#--- (3) Ask for confirmation
#-------------------------------------------------------------------------------
print "Given the above values, are you sure you wish to continue?"
print "The script will pay %d workers a total bonus of %f (average of %f)" % (N, totalBonus, ave)

decision = raw_input("If you are sure you wish to continue, type \'yes\': ")
something = 'hello world!'
if decision=='yes':
    print 'Okay, I will continue with the bonus payment.'

else:
    print 'Okay, since you have not indicated that you want to pay, the script will not run.'
    print 'No bonus has been paid, and the account balance is identical.'
    print 'The final account balance will now be displayed:'
    value=os.system("./getBalance.sh")
    sys.exit()
    
#-------------------------------------------------------------------------------
#--- (4) Pay
#-------------------------------------------------------------------------------
message = "\"Thank you for your participation in our survey.  We appreciate your response.  Along with the stated fixed payment, you have earned a bonus.\""
workers = open(floc+fname+'.csv', 'r')

output = open(floc+fname+'paid.csv','w')
output.write('Worker, Job, bonus, payment,date,time\n')

if decision=='yes':
    for i,line in enumerate(workers):
        if i>0:
            worker = line.split(",")[0]
            job    = line.split(",")[1]
            bonus  = line.split(",")[2]
            bonus  = bonus.replace('\n','')
            #NOTE: to test this script, replace the following os.system call with print.
            os.system('./grantBonus.sh -workerid '+ worker +' -amount ' + bonus + ' -assignment ' + job +' -reason ' + message)
            ptime = time.strftime("%H:%M:%S")
            pdate = time.strftime("%d/%m/%Y")
            output.write(worker+','+job+','+bonus+','+bonus+','+pdate+','+ptime+'\n')

output.close()

#-------------------------------------------------------------------------------
#--- (5) End
#-------------------------------------------------------------------------------
print "The script has now paid all the bonuses and saved a record of payments."
print "The final account balance will be displayed below."
value=os.system("./getBalance.sh")
