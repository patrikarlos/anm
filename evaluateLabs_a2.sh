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
    rm -rf /tmp/A2/*
    echo "[EvalLab] /tmp/A2/"
    ls /tmp/A2/
    echo "[EvalLab] Copying; cp -r $student/* /tmp/A2"
    cp -r "$student"/* /tmp/A2
    cd /tmp/A2

    ls

    ## Remove txt||pdf from filename
    rename 's/\.txt$//' *.txt
    echo "[EvalLab] Executing test" 
    $myBasedir/A2/checkA2.sh
    ls
    echo "[EvalLab] Removing /tmp/A2 folder. "
    rm -rf /tmp/A2/*
    echo "********************DELIMITER****************"
    echo "[EvalLab] Killing snmpd"
    sudo killall snmpd
done
