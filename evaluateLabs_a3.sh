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

rm  $myBasedir/myPids
rm $myBasedir/myFolders


for student in $myRootDir/*
do 
    echo "[EvalLab] Checking $student "
    studTmp=$(mktemp -d /tmp/evaluation-a3-XXXXXXXX)
    echo "$studTmp" >> $myBasedir/myFolders
    echo "[EvalLab] $student data will be in $studTmp"
    echo "[EvalLab] Copying; cp -r $student/* $studTmp"
    cp -r "$student"/* "$studTmp/"
    echo "Evaluating: $student " > "$studTmp/student.txt"
    ls $studTmp

    ## Remove txt||pdf from filename
    echo "[EvalLab] Rename"
    rename 's/\.txt$//' $studTmp/*.txt
    ls $studTmp
    echo "[EvalLab] Executing test" 
    echo "[EvalLab] $myBasedir/A3/checkA3.sh $myBasedir/A3/checkA3.conf $studTmp &"
    $myBasedir/A3/checkA3.sh $myBasedir/A3/checkA3.conf $studTmp 
    studPID=$!
    echo "Showing picture"
    gwenview $studTmp/result.png 
    echo "Checking log file"
    grep -i ERROR $studTmp/test.log
    echo "Did you see any ERROR?"
    echo "$studPID" >> $myBasedir/myPids
    echo "$student evaluation.pid = $studPID "
    echo "********************DELIMITER****************"
    read -p "Press enter to continue"

done

echo "Data, PIDS"
cat $myBasedir/myPids
echo "Data, folders"
cat $myBasedir/myFolders


echo "Waiting for checks to complete"

while pgrep -fl "checkA3.sh" >/dev/null; do echo -n "x";sleep 5; done

echo "Checks Complete."

for fold in $(cat myFolders); do 
    echo "Looking for ERROR in $fold/test.log"
    grep -i ERROR $fold/test.log

done

