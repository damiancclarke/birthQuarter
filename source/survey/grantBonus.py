# grantBonus.py
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
# This script pays bonuses on MTurk.  There is error capture to ensure that bonu
# ses aren't too large, and only with confirmation will the script run.
#

import os

cloc = "/home/damian/computacion/MTurk/aws-mturk-clt-1.3.1/bin/"

os.system("export JAVA_HOME=/usr")
os.chdir(cloc)
value=os.system("./getBalance.sh")


