#!/bin/bash

if [ "$1" == "-h" ]; then
    echo "Evaluate ANM labs.";
    echo "Usage:"
    echo "$1 <labfolder>"
    echo "Labfolder contains the downloaded folder from Its learning."
    exit
fi

myBasedir=$(pwd)
logType=1
#timestr=$(date +%Y-%m-%d_%H%M)
#feedbackFile="$myBasedir/Feedback".$timestr."log"
myRootDir=$1

source Wrapup/supportfunc

#logIt "Feedback will be in $feedbackFile"



for student in $myRootDir/*
do 

    logIt "Checking $student in $myRootDir"
    logIt " "
    logIt "-begin-student- "
    logIt " "

    ##Find the archive
    archives=$(ls "$student"/*.tar.gz | wc -l )
    if [ "$archives" != "1" ]; then
	logIt "Missing archive, or too many"  
	logIt "Missing archive (tar.gz) or too many files submitted"
	logIt "You should submit one archive (<coursecode>-<userid>.tar.gz, see lab assignment for details."
	logIt "Your submission contained "
	logIt $(ls -la *.tar.gz)
	continue;
    fi

    archivename=$(ls "$student"/*.tar.gz)
    logIt "One archive found, $archivename." 

    userid=$(basename "$archivename" .tar.gz)
    array=(${userid//-/ })
    classid=${array[0]}
    userid=${array[1]}
    logIt "Class and UserId (based on archive name) => $classid and $userid" 
#    tar -zxvf *.tar.gz 
    bname=$(echo "$classid-$userid")
    builddir=$(mktemp -t -d ANM-XXXX )
    fullpath="$archivename"
    logIt "Extracting Archive ($archivename) into $builddir ."
    logIt "Going into $builddir ." 
    cd $builddir
    tar -zxvf "$fullpath" > unpack.log
    fcount=$(ls | wc -l)
    if (( $fcount > 2 )); then
	logIt "Folder contains too many files ($fcount), should just have one folder and the unpack.log."
	logIt "Generating feedback, then aborting this student."
	## Generate feedback log
	logIt "Your submitted archive did not contain the right information, it should just be a folder <coursecode>-<userid>, see lab assignment for details." 
	subfiles=$(ls -la | grep -v 'unpack.log')
	logIt "$subfiles"
	cd ..	
#	rm -rf $builddir
	continue;
    fi
    logIt "Copying reference db.conf" 
    cp -v "$myBasedir/Wrapup/db.conf" "$builddir/"
    logIt "Entering user folder, $classid-$userid . "
   
    logIt "Calling:     $myBasedir/Wrapup/checkMe.sh '$classid-$userid' '$builddir/mylog' 2"
    $myBasedir/Wrapup/checkMe.sh "$classid-$userid" "$builddir/mylog" 2
    
    logIt "Returned from test. "
    sleep 1
    
    status=$(grep -i "Missing" "$builddir/mylog" | wc -l)
    logIt "There were $status 'Missing' items."

    status=$(grep -i "Error" "$builddir/mylog" | wc -l)
    logIt "There were $status 'Error' items."

    ## Assignments done
    
    logIt "Preparing $builddir that we can read it"
    chmod -R ag+rwx $builddir
    logIt " "
    logIt "-end-student- "
    logIt " "
done
