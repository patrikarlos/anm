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



for student in $myRootDir/*
do 
    echo "[EvalLab] Checking $student; in $myRootDir"
    studTmp=$(mktemp -d /tmp/evaluation-a4-XXXXXXXX)
    echo "$studTmp" >> $myBasedir/myFolders
    echo "[EvalLab] $student data will be in $studTmp"
    echo "[EvalLab] Copying; cp -r $student/* $studTmp"
    cp -r "$student"/* "$studTmp/"
    ls $studTmp

    cd $studTmp
    ## Remove txt||pdf from filename
    rename 's/\.txt$//' *.txt
    echo "[EvalLab] Executing test" 
    $myBasedir/A4/checkA4.sh $studTmp


    echo "$studPID" >> $myBasedir/myPids
    echo "$student evaluation.pid = $studPID "
    echo "********************DELIMITER****************"
    read -p "Press enter to continue"
done
