
INPUT=data.csv
OLDIFS=$IFS
IFS=,
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read workerid jobid bonus message
do
    echo "Worker ID : $workerid"
    echo "Job ID : $jobid"
    echo "Bonus : $bonus"
    echo "Message : $message"
done < $INPUT
IFS=$OLDIFS
