#!/bin/bash

if [ "$1" == "-h" ]; then
    echo "Evaluate ANM labs.";
    echo "Usage:"
    echo "$1 <labfolder>"
    echo "Labfolder contains the downloaded folder from Its learning."
    exit
fi


myBasedir=$(pwd)
timestr=$(date +%Y-%m-%d_%H%M)
feedbackFile="$myBasedir/Feedback".$timestr."log"
echo "Feedback will be in $feedbackFile"


myRootDir=$1
cd "$myRootDir"
echo "Going into $myRootDir"
for student in *
do 
    echo "[EvalLab] Checking $student; in $myRootDir"
    cd "$myRootDir"
    echo "[EvalLab] Cleaning /tmp/A2/"
    rm -rf /tmp/A2
    mkdir /tmp/A2
    echo "[EvalLab] /tmp/A2/"
    ls /tmp/A2/
    echo "[EvalLab] Copying; cp -r $myRootDir/$student/* /tmp/A2"
    cp -rv "$myRootDir/$student"/* /tmp/A2
    cd /tmp/A2

    echo "[EvalLab] content of /tmp/A2"
    ls

    ## Remove txt||pdf from filename
    rename 's/\.txt$//' *.txt
    chmod a+x /tmp/A2/prober
    dos2unix /tmp/A2/prober
    echo "[EvalLab] content of /tmp/A2"
    ls -la 
    echo "[EvalLab] Checking if any prober runs..interference with snmp."
    if pidof -x "prober" >/dev/null; then
	echo "[prober] Allready running"
	echo "        killing"
	q=$(pidof -x "prober")
	echo "Got this; $q <>"
	pkill prober
    else 
	echo " Did not detect any prober"
	q=$(pidof -x "prober")
	echo "Got this; $q <>"
    fi


    echo "[EvalLab] Executing test: $student"

    
    $myBasedir/A2/checkA2.sh
    ls

    echo "student name:$student " > /tmp/A2/student.txt
    studTmp=$(mktemp -d /tmp/evaluation-a2-XXXXXXXX)
    echo "[EvalLab] Moving /tmp/A2 to $studTmp ."
    mv  /tmp/A2/* $studTmp
    echo "********* $student **************************"
    echo "********************DELIMITER****************"
    read -p "Press enter to continue"
#    echo "[EvalLab] Killing snmpd"
#    sudo killall snmpd
done
