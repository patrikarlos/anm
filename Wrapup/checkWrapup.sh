#!/bin/bash

#git log --pretty=format:'%ci %cn %H' -n 1
version='2017-10-27 17:35:39 +0200 Patrik Arlos b47eded587e5131a321190536ac9248044208560'

logIt() {
    theStuff="$1"
    logstr=$(echo $(date +"%F %T") "\t(SAL) $theStuff")
    if (( $logType==3 )); then 
	## File and stdout
	echo -e "$logstr " | tee -a $feedbackFile
    elif (( $logType==2 )); then 
	## File only
	echo -e "$logstr " >> $feedbackFile
    elif (( $logType==1 )); then 
	## STDOUT only
	echo -e "$logstr "
    elif (( $logType==0 )); then 
	## Silent
	echo "."
    else
	echo "Unknown logType ($logType). Supports 0-3"
    fi
}

echo "...................................."
echo $(date +"%F %T") "Starting the evaluation of Wraup."
echo $(date +"%F %T") "---STANDALONE VERSION---"
echo "...................................."
echo "This is version"
echo "$version"
echo " "

archivename="$1"

myBasedir=$(pwd)
logType=1
echo "myBasedir = $myBasedir "

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
    logIt "ERROR: Your submitted archive did not contain the right information, it should just be a folder <coursecode>-<userid>, see lab assignment for details." 
    subfiles=$(ls -la | grep -v 'unpack.log')
    logIt "$subfiles"
    cd ..	
    #	rm -rf $builddir
    exit
fi
logIt "Copying reference db.conf" 
cp -v "$myBasedir/db.conf" "$builddir/"
logIt "Entering user folder, $classid-$userid . "

$myBasedir/checkMe.sh "$classid-$userid" "$builddir/mylog" 2

logIt "Returned from test. "
sleep 1

status=$(grep -i "Missing" "$builddir/mylog" | wc -l)
logIt "There were $status 'Missing' items."

status=$(grep -i "Error" "$builddir/mylog" | wc -l)
logIt "There were $status 'Error' items."

logIt "Here is the log"
cat "$builddir/mylog"

## Assignments done
