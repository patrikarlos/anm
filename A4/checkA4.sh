#!/bin/bash
# Test for A4 for ET2536

##VARIABLES; must be filled correctly
internetNIC=br0



startDir=$(pwd) # Grab a copy of current directory,
myBase=$1

if [ ! -e "$myBase" ]; then
    echo "[ CA4: SETUP ] did not get a path "
    echo "          I assume the worst, exiting." 
    exit 1 
fi


echo "Transporting to $myBase" 
cd $myBase


abortWdem() {
demDied=$(cat snmpdtrap.log | grep 'Received TERM or STOP signal...  shutting down')
if [[ ! -z "$demDied" ]]; then
    echo "[SNMPtrapd] Died OK";
else 
    echo "[SNMPtrapd] did not report its death correctly, or it did not die (did it start?)"
fi
}

killServers() {
    echo "***Killing snmptrapd, $snmpPid***"  | tee -a test.log
    kill -- "$snmpPid"
    backprocs=$(ps -elf | grep "$snmpPid")
    echo "$backprocs "  | tee -a test.log
    echo "--------------------"  | tee -a test.log
    sleep 5


    echo "***Killing webserver, $webPid ***"  | tee -a test.log
    kill -- "$webPid"   
    backprocs=$(ps -elf | grep "$webPid")
    echo "$backprocs " | tee -a test.log
    echo "--------------------" | tee -a test.log
    sleep 5
}


#git log --pretty=format:'%ci %cn %H' -n 1
version='2017-10-27 17:35:39 +0200 Patrik Arlos b47eded587e5131a321190536ac9248044208560'






echo "...................................."  | tee test.log
echo $(date) . "Starting the evaluation of A4." | tee -a test.log
echo "...................................." | tee -a test.log
echo "This is version" | tee -a test.log
echo "$version" | tee -a test.log
echo " " | tee -a test.log

if pidof -x "snmptrapd" >/dev/null; then
    echo "[SNMPtrapd] Allready running" | tee test.log
    echo "        Leaving." > test.log
    exit 1
fi

if [ ! -e snmptrapd.conf ]; then
    echo "Error: Cant find snmptrapd.conf" | tee -a test.log
    echo "Folder contains:" >> test.log
    ls > test.log
    echo "        Leaving." >> test.log
    exit 1
fi

if [ ! -e traphandler ]; then
    echo "Error: Cant find traphandler" | tee -a test.log
    echo "Folder contains:" >> test.log
    ls  > test.log
    echo "        Leaving." >> test.log
    exit 1
fi

if [ ! -e getStatus.php ]; then
    echo "Error: Cant find getStatus.php" | tee -a test.log
    echo "Folder contains:" >> test.log 
    ls  > test.log
    echo "        Leaving." >> test.log
    exit 1
fi

if [ ! -e getTrapR.php ]; then
    echo "Error: Cant find getTrapR.php" | tee -a test.log
    echo "Folder contains:" >> test.log
    ls  > test.log
    echo "        Leaving." >> test.log
    exit 1
fi

if [ ! -e setTrapR.php ]; then
    echo "Error: Cant find setTrapR.php" | tee -a test.log
    echo "Folder contains:" >> test.log
    ls  > test.log
    echo "        Leaving." >> test.log
    exit 1
fi

if [ ! -e config.php ]; then
    echo "Error: Cant find config.php" | tee -a test.log
    echo "Folder contains:" >> test.log
    ls  > test.log
    echo "        Leaving." >> test.log
    exit 1
fi

lh=$(cat snmptrapd.conf  | grep -i snmpTrapdAddr | grep  localhost)
lip=$(cat snmptrapd.conf  | grep -i snmpTrapdAddr | grep  127.0.0.1)
lprotport=$(cat snmptrapd.conf  | grep -i snmpTrapdAddr | grep  50162)

echo "lh=$lh"
echo "lip=$lip"
echo "lprotport=$lprotport"

if [[ ! -z "$lh" ]]; then
    echo "[SNMPtrapd] Will only answer on localhost;ERROR" | tee test.log
    echo "        The check for snmpTrapdAddr | grep localhost => $lh ."   >> test.log      
    exit 1
elif [[ ! -z "$lip" ]]; then
    echo "[SNMPtrapd] Will only answer on 127.0.0.1;ERROR" | tee test.log
    echo "        The check for snmpTrapdAddr | grep 127.0.0.1 => $lip ."  >> test.log       
    exit 1
elif [[ ! -z "$lprotport" ]]; then
    echo "[SNMPtrapd] Hopefully ok" >> test.log
else
    echo "[SNMPtrapd] Some error, missing something.ERROR" | tee -a test.log
    exit 1
fi

if [[ $(grep 'traphandler' snmptrapd.conf) ]]; then
    echo "[SNMPtrapd] traphandler was found in config file" >> test.log
else
    echo "[SNMPtrapd] MISSING traphandler will not work" >> test.log
    exit 1
fi

if [[ $(grep -i 'disableAuthorization' snmptrapd.conf) ]]; then
     echo "[SNMPtrapd] disableAuthorization found in config file, keeping it simple :)" >> test.log
fi



echo $( date +"%Y-%M-%d %H:%m:%S") " Starting snmptrapd " | tee -a test.log



# ##Start SNMPd, and log the output to file.
snmptrapd -Onvq -n -f -c snmptrapd.conf -C -a -Lf snmptrapd.log >> trap.log &
snmpPid=$!

echo $( date +"%Y-%M-%d %H:%m:%S") " Snmptrapd started; $snmpPid "

## check that it works..


echo $( date +"%Y-%M-%d %H:%m:%S") " Starting webserver " | tee -a test.log
php -S 127.0.0.1:8000 &> webserver.log &
webPid=$!

echo $( date +"%Y-%M-%d %H:%m:%S") " Webserver started; $webPid "
echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting for both to start. "
sleep 10

sudo netstat -anp | grep 8000
sudo netstat -anp | grep 50162



echo "------------REAL TEST----------------"

echo -n $( date +"%Y-%M-%d %H:%m:%S") "Checking:  that there is nothing in the system (initialize the db), "
response=$(curl -s "http://127.0.0.1:8000/getStatus.php")
if [ "$response" ==  "FALSE" ]; then
    echo " OK"
else
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (FALSE). "
    killServers
    exit 1
fi





echo -n $( date +"%Y-%M-%d %H:%m:%S") " Set trapdestination"
response=$(curl -s "http://127.0.0.1:8000/setTrapR.php?ip=192.168.184.1&port=161&community=public")
if [ "$response" ==  "OK" ]; then
    echo " OK"
else
    echo " WebServer; responded $response thats not OK"
fi

echo -n $( date +"%Y-%M-%d %H:%m:%S") " Get trapdestination"
response=$(curl -s "http://127.0.0.1:8000/getTrapR.php")
if [ "$response" ==  "public@192.168.184.1:161" ]; then
    echo " OK"
else
    echo " WebServer; responded $response thats not what I expected. "
fi

echo -n $( date +"%Y-%M-%d %H:%m:%S") "Checking:  that there is nothing in the system, "
response=$(curl -s "http://127.0.0.1:8000/getStatus.php")
if [ "$response" ==  "FALSE" ]; then
    echo " OK"
else
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (FALSE). "
    killServers
    exit 1
fi


echo $( date +"%Y-%M-%d %H:%m:%S") ">> simple enter device tests" 
echo -n $( date +"%Y-%M-%d %H:%m:%S") " Setting Bubbly to OK"
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.3 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "bubbly.bth.se" .1.3.6.1.4.1.41717.10.2 i "1"
#echo "Sleep 1; to give traphandler time to work"
sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php")
if [ "$response" ==  "FALSE" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (bubbly should be in). "
    killServers
    exit 1
else
    echo -n " OK "
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "bubbly.bth.se" == "$name" ]; then
	if [ "1" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; Bubbly found, but with $status != 1 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; bubbly.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi


echo -n $( date +"%Y-%M-%d %H:%m:%S") " Setting Trouble to OK"
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.4 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "trouble.bth.se" .1.3.6.1.4.1.41717.10.2 i "1"
#echo "Sleep 1; to give traphandler time to work"
sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep trouble)
if [ -z "$response" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (trouble should be in). "
    killServers
    exit 1
else
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "trouble.bth.se" == "$name" ]; then
	if [ "1" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; Trouble found, but with $status != 1 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; trouble.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi

echo $( date +"%Y-%M-%d %H:%m:%S") "<< simple enter device tests" 

#------------------ERROR Trap----------------


echo $( date +"%Y-%M-%d %H:%m:%S") ">> Setting www.bth.se to error state "
echo $( date +"%Y-%M-%d %H:%m:%S") "tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &" 
sudo tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &
tpcumppid=$!

sleep 1
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.2 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "www.bth.se" .1.3.6.1.4.1.41717.10.2 i "3"
#echo "Sleep 1; to give traphandler time to work"
sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep www)
if [ -z "$response" ]; then
    echo " ERROR:  (Error Trap) "
    echo " WebServer; responded $response thats not what I expected (www should be in). "
    killServers
    exit 1
else
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "www.bth.se" == "$name" ]; then
	if [ "3" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo " ERROR; www found, but with $status != 3 "
	    killServers
	    exit 1
	fi
    else
	echo " ERROR; www.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi

echo $( date +"%Y-%M-%d %H:%m:%S") " Checking if trap has been sent (Error trap) "
timeOut=0
while [ ! -s blob ]; do
    fs=$(wc -c blob)
    echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting [$timeOut] for trace to arrive, current $fs bytes" 
    sleep 1
    ((timeOut++))

    if [[ "$timeOut" > 10 ]]; then
	echo $( date +"%Y-%M-%d %H:%m:%S") " Waited long enough, giving up."
	echo " ERROR did not get any trap within 10 s. "
	killServers
	exit 1
    fi
done

read oid myoid1 myoid2 <<<$(cat blob  | awk '{print $7,$12,$13}')
if [[ -z "$oid" || -z "$myoid1" || -z "$myoid2" ]]; then 
    echo " ERROR : One, or multiple, variables were empty. That's not good"
    echo " oid = $oid myoid1= $myoid1 myoid2= $myoid2 ."
    killServers
    exit 1
fi

if [[ $myoid1 == *"1.3.6.1.4.1.41717.20.1"* ]]; then
    if [[ $myoid1 == *"www.bth.se"* ]]; then
	echo "FQDN found in $myoid1 "
	fqdnIn=1;
    else
	echo "ERROR: did not detect the FQDN, expected www.bth.se got $myoid1 ."
	killServers
	exit 1
    fi
elif [[ $myoid2 == *"1.3.6.1.4.1.41717.20.1"* ]]; then
    if [[ $myoid2 == *"www.bth.se"* ]]; then
	echo "FQDN found in $myoid2"
	fqdnIn=1;
    else
	echo "ERROR: did not detect the FQDN, expected www.bth.se got $myoid2 ."
	killServers
	exit 1
    fi
else 
    echo " ERRROR : Cant find 1.3.6.1.4.1.41717.20.1, checked $myoid1 and $myoid2 ."
    killServers
    exit 1
fi

if [[ $fqdnIn==1 ]]; then
    tval=$(echo "$myoid2" | awk -F'=' '{print $2}')
else 
    tval=$(echo "$myoid1" | awk -F'=' '{print $2}')
fi
echo "Trap registered $tval (not checking) " 

echo $( date +"%Y-%M-%d %H:%m:%S") "<< Setting www.bth.se to error state "
#---------------/ERROR TRAP     




#------------------NORMAL 
echo $( date +"%Y-%M-%d %H:%m:%S") ">> www.bth.se to 0"
echo "tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &" 
sudo rm -f blob
sudo tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &
tpcumppid=$!

sleep 1
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.2 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "www.bth.se" .1.3.6.1.4.1.41717.10.2 i "0"
#echo "Sleep 1; to give traphandler time to work"
sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep www)
if [ -z "$response" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (www should be in). "
    killServers
    exit 1
else
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "www.bth.se" == "$name" ]; then
	if [ "0" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; www found, but with $status != 0 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; www.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi

echo "Checking if trap has been sent. "
timeOut=0
while [ ! -s blob ]; do
    fs=$(wc -c blob)
    echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting [$timeOut] for trace to arrive, current $fs bytes" 
    sleep 1
    ((timeOut++))

    if [[ "$timeOut" -gt "5" ]]; then
	echo $( date +"%Y-%M-%d %H:%m:%S") " Waited long enough, did not get any trap within 5 s. "
	echo "sudo killall tcpdump"
	sudo killall tcpdump
	echo "killing tcpdump ($tpcumppid) , and waiting a while to let the file settle."
	sleep 5 
	break
    fi
done

fize=$(wc -c blob) 
if [[ "$fize" > "20"  ]]; then 
    echo $( date +"%Y-%M-%d %H:%m:%S") " ERROR tcpdump should not catch any trap.."
    cat blob
    killServers
    exit 1
else 
    echo " OK, no trap was caught"
fi

echo $( date +"%Y-%M-%d %H:%m:%S") "<< www.bth.se to 0"
#---------------/NORMAL




#---------Dev1 danger
echo $( date +"%Y-%M-%d %H:%m:%S") ">>Running Danger test, device 1 (bubbly)" 
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.3 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "bubbly.bth.se" .1.3.6.1.4.1.41717.10.2 i "2"
sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep bubbly)
if [ "$response" ==  "FALSE" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (bubbly should be in). "
    killServers
    exit 1
else
    echo " OK"
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "bubbly.bth.se" == "$name" ]; then
	if [ "2" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; Bubbly found, but with $status != 2 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; bubbly.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi
#---------Dev2 danger
echo $( date +"%Y-%M-%d %H:%m:%S") " Adding device 2 (trouble) " 
echo "tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &" 
sudo tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &
tpcumppid=$!
sleep 1 
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.4 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "trouble.bth.se" .1.3.6.1.4.1.41717.10.2 i "2"


sleep 1
echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep trouble)
if [ "$response" ==  "FALSE" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (trouble should be in). "
    killServers
    exit 1
else
    echo " OK"
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "trouble.bth.se" == "$name" ]; then
	if [ "2" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; trouble found, but with $status != 2 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; trouble.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi

#checking if both devices are in state '2'

#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep '| 2 |' | wc -l)
if [ "$response" !=  "2" ]; then
    echo " ERROR: "
    echo " WebServer; responded that there were $response devices danger thats not what I expected."
    echo " Server: " $(curl -s "http://127.0.0.1:8000/getStatus.php")
    killServers
    exit 1
else
    echo " OK, we hope the status is correct."
fi

echo $( date +"%Y-%M-%d %H:%m:%S") " Check the trap."

timeOut=0
while [ ! -s blob ]; do
    fs=$(wc -c blob)
    echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting [$timeOut] for trace to arrive, current $fs bytes" 
    sleep 1
    ((timeOut++))

    if [[ "$timeOut" -gt "10" ]]; then
	echo $( date +"%Y-%M-%d %H:%m:%S") " Waited long enough ($timeOut), giving up."
	echo " ERROR did not get any trap within 10 s. "
	killServers
	exit 1
    fi
done
echo $( date +"%Y-%M-%d %H:%m:%S") " This is blob (two devices)"
cat blob
echo $( date +"%Y-%M-%d %H:%m:%S") " This was blob (two devices)"



echo ".1.3.6.1.4.1.41717.30.1" > myOids
echo ".1.3.6.1.4.1.41717.30.2" >> myOids 
echo ".1.3.6.1.4.1.41717.30.3" >> myOids
echo ".1.3.6.1.4.1.41717.30.4" >> myOids
echo ".1.3.6.1.4.1.41717.30.5" >> myOids
echo  ".1.3.6.1.4.1.41717.30.6" >> myOids
echo  ".1.3.6.1.4.1.41717.30.7" >> myOids
echo  ".1.3.6.1.4.1.41717.30.8" >> myOids

#Print the entriesf after 7 (space separates), the grab the lines with our MIB (41717.30), and finally ditch the values print only the oids. 
awk '{out=""; for(i=7;i<=NF;i++){printf "%s\n",$i};}' blob | grep '41717.30.' > refinedBlob
awk -F'=' '{print $1}' refinedBlob > oidsInReq

if [ $(diff myOids oidsInReq|wc -l) -ne 0 ]; then 
    echo "ERROR There is a discrepancy betweeen what was expected, and was detected"
    echo "These oids were found"
    cat oidsInReq
    echo "expected these"
    cat myOids
    killServers
    exit 1
else
    echo "All OIDS are present, no extra no missing."
fi

if [[ $(grep 'bubbly' refinedBlob) && $(grep 'trouble' refinedBlob) ]]; then
    echo "Got both bubbly and trouble"
else
    echo "ERROR missed either bubbly or trouble in the trap."
    echo "Found "
    cat refinedBlob
fi


###############--Danger with three devices..

#---------Dev3 danger
echo $( date +"%Y-%M-%d %H:%m:%S") " Running danger device 3 (www)" 
echo "tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &" 
sudo tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &
tpcumppid=$!
sleep 1 
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.2 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "www.bth.se" .1.3.6.1.4.1.41717.10.2 i "2"


sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep '| 2 |' | grep www)
if [ "$response" ==  "FALSE" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (www should be in). "
    killServers
    exit 1
else
    echo " OK"
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "www.bth.se" == "$name" ]; then
	if [ "2" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; www found, but with $status != 2 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; trouble.bth.se was not found, found $name , based on $response |ol|"
	killServers
	exit 1
    fi
fi

#checking if all three devices are in state '2'

echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep '| 2 |' | wc -l)
if [ "$response" !=  "3" ]; then
    echo " ERROR: "
    echo " WebServer; responded that there were $response devices danger thats not what I expected."
    echo " Server: " $(curl -s "http://127.0.0.1:8000/getStatus.php")
    killServers
    exit 1
else
    echo " OK, we hope its correct."
fi

echo "Check the traps.."

timeOut=0
while [ ! -s blob ]; do
    fs=$(wc -c blob)
    echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting [$timeOut] for trace to arrive, current $fs bytes" 
    sleep 1
    ((timeOut++))

    if [[ "$timeOut" -gt "10" ]]; then
	echo $( date +"%Y-%M-%d %H:%m:%S") " Waited long enough ($timeOut), giving up."
	echo " ERROR did not get any trap within 10 s. "
	killServers
	exit 1
    fi
done

echo $( date +"%Y-%M-%d %H:%m:%S") " This is blob (three devices)"
cat blob
echo $( date +"%Y-%M-%d %H:%m:%S") " This was blob (three devices)"




echo ".1.3.6.1.4.1.41717.30.9" >> myOids
echo  ".1.3.6.1.4.1.41717.30.10" >> myOids
echo  ".1.3.6.1.4.1.41717.30.11" >> myOids
echo  ".1.3.6.1.4.1.41717.30.12" >> myOids

#Print the entriesf after 7 (space separates), the grab the lines with our MIB (41717.30), and finally ditch the values print only the oids. 
awk '{out=""; for(i=7;i<=NF;i++){printf "%s\n",$i};}' blob | grep '41717.30.' > refinedBlob
awk -F'=' '{print $1}' refinedBlob > oidsInReq

if [ $(diff myOids oidsInReq|wc -l) -ne 0 ]; then 
    echo "ERROR There is a discrepancy betweeen what was expected, and was detected"
    echo "These oids were found"
    cat oidsInReq
    echo "expected these"
    cat myOids
    killServers
    exit 1
else
    echo "All OIDS are present, no extra no missing."
fi

if [[ $(grep 'bubbly' refinedBlob) && $(grep 'trouble' refinedBlob) && $(grep 'www' refinedBlob) ]]; then
    echo "Got both bubbly and trouble"
else
    echo "ERROR missed either bubbly or trouble in the trap."
    echo "Found "
    cat refinedBlob
fi
#-----------------END danger test
echo $( date +"%Y-%M-%d %H:%m:%S") "<< DANGER TEST is over" 


echo $( date +"%Y-%M-%d %H:%m:%S") " Checking if the thing appends dangers to error traps. "

echo $( date +"%Y-%M-%d %H:%m:%S") " Poor jupiter.bth.se to goes to error state "
echo "tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &" 
sudo tcpdump -c 1 -ttt -n -i $internetNIC ip dst 192.168.184.1 and udp and dst port 161 > blob &
tpcumppid=$!

sleep 1
sudo snmptrap -v 1 -c public 127.0.0.1:50162 .1.3.6.1.4.1.41717.10 10.0.2.20 6 247 ' ' .1.3.6.1.4.1.41717.10.1 s "jupiter.bth.se" .1.3.6.1.4.1.41717.10.2 i "3"
#echo "Sleep 1; to give traphandler time to work"
sleep 1
#echo "curl -s 'http://127.0.0.1:8000/getStatus.php'"
response=$(curl -s "http://127.0.0.1:8000/getStatus.php" | grep jupiter)
if [ -z "$response" ]; then
    echo " ERROR: "
    echo " WebServer; responded $response thats not what I expected (jupiter should be in). "
    killServers
    exit 1
else
    read name status time <<<$(echo $response |awk -F '|' '{print $1, $2, $3}')
    if [ "jupiter.bth.se" == "$name" ]; then
	if [ "3" == "$status" ]; then 
	    echo " Good enough"
	else
	    echo "ERROR; jupiter found, but with $status != 3 "
	    killServers
	    exit 1
	fi
    else
	echo "ERROR; jupiter.bth.se was not found, found $name "
	killServers
	exit 1
    fi
fi

echo $( date +"%Y-%M-%d %H:%m:%S") " Checking if trap was sent. "
timeOut=0
while [ ! -s blob ]; do
    fs=$(wc -c blob)
    echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting [$timeOut] for trace to arrive, current $fs bytes" 
    sleep 1
    ((timeOut++))

    if [[ "$timeOut" > 10 ]]; then
	echo $( date +"%Y-%M-%d %H:%m:%S") " Waited long enough, giving up."
	echo " ERROR did not get any trap within 10 s. "
	killServers
	exit 1
    fi
done
echo $( date +"%Y-%M-%d %H:%m:%S") "<blob with error trap>"
cat blob
echo $( date +"%Y-%M-%d %H:%m:%S") "</blob>"

read oid myoid1 myoid2 <<<$(cat blob  | awk '{print $7,$12,$13}')
if [[ -z "$oid" || -z "$myoid1" || -z "$myoid2" ]]; then 
    echo " ERROR : One, or multiple, variables were empty. That's not good"
    echo " oid = $oid myoid1= $myoid1 myoid2= $myoid2 ."
    killServers
    exit 1
fi

if [[ $myoid1 == *"1.3.6.1.4.1.41717.20.1"* ]]; then
    if [[ $myoid1 == *"jupiter.bth.se"* ]]; then
	echo "FQDN found in $myoid1 "
	fqdnIn=1;
    else
	echo "ERROR: did not detect the FQDN, expected jupiter.bth.se got $myoid1 ."
	killServers
	exit 1
    fi
elif [[ $myoid2 == *"1.3.6.1.4.1.41717.20.1"* ]]; then
    if [[ $myoid2 == *"jupiter.bth.se"* ]]; then
	echo "FQDN found in $myoid2"
	fqdnIn=1;
    else
	echo "ERROR: did not detect the FQDN, expected www.bth.se got $myoid2 ."
	killServers
	exit 1
    fi
else 
    echo " ERRROR : Cant find 1.3.6.1.4.1.41717.20.1, checked $myoid1 and $myoid2 ."
    killServers
    exit 1
fi

if [[ $fqdnIn==1 ]]; then
    tval=$(echo "$myoid2" | awk -F'=' '{print $2}')
else 
    tval=$(echo "$myoid1" | awk -F'=' '{print $2}')
fi
echo "Trap registered $tval (not checking) " 


echo $( date +"%Y-%M-%d %H:%m:%S") "Leaving with the current state"
curl -s "http://127.0.0.1:8000/getStatus.php"




echo "------------END TEST-----------------"

killServers
echo "It might have been a great Success"



