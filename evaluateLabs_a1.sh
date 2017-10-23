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
    echo "[EvalLab] Cleaning /tmp/A1/"
    rm -rf /tmp/A1/*
    echo "[EvalLab] /tmp/A1/"
    ls /tmp/A1/
    echo "[EvalLab] Copying; cp -r $student/* /tmp/A1"
    cp -r "$student"/* /tmp/A1
    cd /tmp/A1

    ls

    ## Remove txt||pdf from filename
    rename 's/\.txt$//' *.txt
    echo "********************START: $student****************"
    echo $(date) 
    echo "********************************************"
    echo "[EvalLab] Executing test for " 

    $myBasedir/A1/checkA1.sh
    ls
    echo "[EvalLab] Removing /tmp/A1 folder. "
    rm -rf /tmp/A1/*
    echo "********************END: $student****************"
    echo "[EvalLab] Killing snmpd"
    sudo killall snmpd
done
