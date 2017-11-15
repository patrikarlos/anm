#!/bin/bash

myBasedir=$(pwd)

myRootDir="$1"
feedbackFile="$2"
logType="$3"


if [ -z "$logType" ]; then 
    logType=1
fi


version='2017-11-15 11:38:50 +0100 Patrik Arlos 17bfb90ef03e1c6fca6ef65271b1f6b0482305df'


logIt() {
    theStuff="$1"
    logstr=$(echo $(date +"%F %T") "\t(Root) $theStuff")
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

checkFile(){
    theFile="$1"
#    logIt "Checking $theFile"
    if [[ -f "$theFile" ]]; then
	logIt "Checking $theFile, OK"
    else
	logIt "Checking $theFile, Missing"
    fi
}

checkFileOpt(){
    theFile="$1"
#    logIt "Checking $theFile"
    if [[ -f "$theFile" ]]; then
	logIt "Checking $theFile (optional), OK"
    fi
}

checkFileMode(){
    theFile="$1"
    if [[ -f "$theFile" ]]; then
#	logIt "Checking $theFile"
	if [[ -x "$theFile" ]]; then
	    logIt "$theFile it's executable"
	else
	    logIt "$theFile is missing the executable bit and will not start (man chmod)."
	fi
    fi
}

echo "...................................."
echo $(date +"%F %T") "Starting the evaluation of Wraup."
echo "...................................."
echo "This is version"
echo "$version"
echo "

echo $(date +"%F %T") "Log.info myRootDir=$myRootDir" 
echo $(date +"%F %T") "feedbackFile='$feedbackFile'"
echo $(date +"%F %T") "logType='$logType' "

cd "$myRootDir"
#cd "$classid-$userid"
currdir=$(pwd) 
logIt "We will check the files in $currdir"
logIt "Checking files in the root dir (readme.txt db.conf) "
readmeCnt=$(ls | grep -i readme.txt | wc -l )
if (( $readmeCnt >= 1 )) ; then
    lenreadme=$(ls -la | grep -i readme.txt | head -1 | awk '{print $5}')
    logIt "readme.txt present and has $lenreadme characters"
else
    exit
fi

logIt "Checking main db.conf, in " $(pwd) 
dbconfCnt=$(ls | grep -i db.conf | wc -l )
if (( $dbconfCnt >= 1 )) ; then
    dbconflen=$(ls -la | grep -i db.conf | head -1 | awk '{print $5}')
    logIt "db.conf present and has $dbconflen characters"
    logIt "looking for variables in db.conf"
    hvar=$(grep -i host db.conf | wc -l)
    portvar=$(grep -i port db.conf | wc -l)
    dbvar=$(grep -i database db.conf | wc -l)
    unvar=$(grep -i username db.conf | wc -l)
    pwvar=$(grep -i password db.conf | wc -l)
    if (( $hvar &&  $portvar && $dbvar  && $unvar &&  $pwvar )); then
	logIt "All variables seems present"
	leftLines=$(grep -v -i port db.conf | grep -v -i database | grep -v -i host | grep -v -i username | grep -v -i password | wc -l )
	logIt "There are $leftLines that did not match the parameters."
	logIt "Replacing with my db.conf"
	logIt "(backup)db.conf db_orginal.conf  "
	cp db.conf db_orginal.conf 
	logIt "(copy) ($myBasedir/db.conf -> db.conf) : "
	cp $myBasedir/db.conf db.conf 
	logIt "Difference between db_original and the used". 
	slurp=$(echo " "; diff -y db.conf db_orginal.conf)
	logIt "$slurp"
	
    else
	logIt "Missing some variables";
	missVar=""
	for variable in host port database username password
	do
	    result=$(grep $variable assignment1/db.conf | wc -l)
	    if (( $result==0)); then
		#		    logIt "$variable "
		missVar="$missVar $variable"
	    fi
	done
	logIt "Main: Missing the following variables in db.conf ; $missVar "
    fi
else
    logIt "db.conf is missing from your archive"
fi


logIt "Checking Assignments (assignment1, assignment2 and assignment3"
assCount=0
missA=""
for assin in assignment1 assignment2 assignment3
do 
    if [ -d "$assin" ]; then
	if [ ! -f $assin/readme.txt ]; then
	    logIt "In the folder of your submitted archive, the readme.txt for $assin missing "
	fi
	assCount=$[$assCount + 1]
    else
	logIt "In the folder of your submitted archive, the $assin folder is missing"
	missA="$missA $assin"
    fi
done

slp=$(echo "Got $assCount assignment" in $(pwd))
logIt "$slp"
if (( $assCount < 3 )); then
    logIt "ERROR: You submission misses some assignments ($missA), please update."
    exit;
else 
    slp=$(echo "Checking assignments in " $(pwd))
    logIt "$slp"
    
    ## Assignment 1 starts 
    logIt "Assignment1"
    logIt "Checking report.pdf"
    a2=$(ls -ls assignment1/report.pdf 2>/dev/null | wc -l)
    if (( $a2>=1 )); then
	logIt "One or more PDF files present. ";
    else
	logIt "Missing report (pdf)"
	logIt "Assignment 1: Missing report (as a pdf file)"
    fi
    
    checkFile "assignment1/readme.txt" 
    checkFile "assignment1/mrtgconf"
    checkFileMode "assignment1/mrtgconf"
    checkFile "assignment1/backend"  
    checkFileMode "assignment1/backend"  
    checkFile "assignment1/backend.sh" 
    checkFileMode "assignment1/backend.sh" 
    checkFile "assignment1/index.*" 
    checkFileOpt "assignment1/Makefile" 
    
    


    
    ## Assignment 2 starts
    logIt "Assignment 2"
    checkFile "assignment2/readme.txt"
    checkFileOpt "assignment2/Makefile"
    checkFile "assignment2/backend"
    checkFileMode "assignment2/backend"
    checkFile "assignment2/backend.sh"
    checkFileMode "assignment2/backend.sh"
    checkFile "assignment2/index.*"
    
    
    ## Assignment 3 starts
    logIt "Assignment 3"
    checkFile "assignment3/readme.txt"
    checkFileOpt "assignment3/Makefile"
    checkFile "assignment3/trapDeamon"
    checkFile "assignment3/snmptrapd.conf"
    checkFile "assignment3/index.*"
   
    ## Assignments done
    
fi


