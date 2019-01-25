#!/bin/bash
# Test for A1 for ET2536

##Check snmpd.config


abortWdem() {
demDied=$(cat /tmp/A1/snmpd.log | grep 'Received TERM or STOP signal...  shutting down')
if [[ ! -z "$demDied" ]]; then
    echo "[SNMPd] Died OK";
else 
    echo "[SNMPd] did not report its death correctly, or it did not die (did it start?)"
fi
}

#git log --pretty=format:'%ci %cn %H' -n 1
#version='2017-10-27 17:35:39 +0200 Patrik Arlos b47eded587e5131a321190536ac9248044208560'
version='2017-11-15 11:38:50 +0100 Patrik Arlos 17bfb90ef03e1c6fca6ef65271b1f6b0482305df'

echo "...................................."
echo $(date) . "Starting the evaluation of A1."
echo "...................................."
echo "This is version"
echo "$version"
echo " "

if pidof -x "snmpd" >/dev/null; then
    echo "[SNMPd] Allready running"
    echo "        Leaving."
    exit 1
fi

if [ ! -e /tmp/A1/snmpd.conf ]; then
    echo "Error: Cant find /tm/A1/snmpd.conf";
    echo "Folder contains:"
    ls /tmp/A1
    echo "        Leaving."
    exit 1
fi

if [ ! -e /tmp/A1/subagent ]; then
    echo "Error: Cant find /tm/A1/subagent";
    echo "Folder contains:"
    ls /tmp/A1
    echo "        Leaving."
    exit 1
fi

lh=$(cat /tmp/A1/snmpd.conf  | grep agentAddress | grep  localhost | grep -v '^#' )  
lip=$(cat /tmp/A1/snmpd.conf  | grep agentAddress | grep  127.0.0.1 | grep -v '^#' )
lprotport=$(cat /tmp/A1/snmpd.conf  | grep agentAddress | grep  udp:161)

if [[ ! -z "$lh" ]]; then
    echo "[SNMPd] Will only answer on localhost;ERROR"
    echo "        The check for agentAddress | grep localhost => $lh ."        
    exit 1
elif [[ ! -z "$lip" ]]; then
    echo "[SNMPd] Will only answer on 127.0.0.1;ERROR"
    echo "        The check for agentAddress | grep 127.0.0.1 => $lip ."        
    exit 1
elif [[ -z "$lprotoport" ]]; then
    echo "[SNMPd] Hopefully ok"
else
    echo "[SNMPd] Some error, missing something.ERROR"
    exit 1
fi

if [[ $(grep "\/tmp/\A1\/" /tmp/A1/snmpd.conf) ]]; then
     echo "[SNMPd] Path was found in config file";
else
    echo "[SNMPd] ERROR; did not find '/tmp/A1/', hence its missing a PATH and will not work";
    exit 1
fi

if [[ $(grep '/tmp/A1/subagent["\$]' /tmp/A1/snmpd.conf) ]]; then
     echo "[SNMPd] subagent call was found in config file";
else
    if [[ $(grep "/tmp/A1/subagent['\$]" /tmp/A1/snmpd.conf) ]]; then
	echo "[SNMPd] subagent call was found in config file";
    else
	
	echo "[SNMPd] MISSING call to subagent (wo. extention), will not work";
	echo "Found"
	grep '/tmp/A1/subagent' /tmp/A1/snmpd.conf
	exit 1
    fi
fi







##Create an counters.conf


noIfs=$(( ( RANDOM % 10 )  + 5 ))
myif=1
echo -n "       Creating counters.conf, with $noIfs random interfaces. "
rm -f /tmp/A1/counters.conf
while [ $myif -lt "$noIfs" ]; do
    rate=$[ ( $RANDOM * 3000 ) ]
    echo "$myif,$rate" >> /tmp/A1/counters.conf
    let myif=myif+1
done
let myif=myif+9
rate="1000000000"
echo "$myif,$rate" >> /tmp/A1/counters.conf
echo "Done"


    


# ##Start SNMPd, and log the output to file.
sudo snmpd -f -c /tmp/A1/snmpd.conf -C -a -Lf /tmp/A1/snmpd.log &



##Initial test.
myTimeRef=$(($(date --date '2018-10-01 00:00:00' +%s%N)/1000))
myTimeNow=$(($(date +%s%N)/1000))
myTime=$(( $myTimeNow - $myTimeRef )) 

snmpTime=$(snmpget -Onvq -v2c -c public localhost 1.3.6.1.4.1.4171.50.1)

if [ -z "$snmpTime" ]; then
    echo "[SNMPd] No response/or incorrect, ERROR . ";
    echo "        $snmpTime "
    abortWdem
    exit 1;
fi

echo "Got; $snmpTime "

if [[  $snmpTime == *"No Such Object"* ]]; then
    echo "[SNMPd] Agent does not respond to the time OID (1.3.6.1.4.1.4171.50.1 "
    echo "        $snmpTime"
    abortWdem
    exit 1;
fi

if [[  $snmpTime == *"Incorrect OID"* ]]; then
    echo "[SNMPd] Agent does not respond to the time OID (1.3.6.1.4.1.4171.50.1 "
    echo "        $snmpTime"
    abortWdem
    exit 1;
fi




diff=$(( $myTime - $snmpTime ))

if [ "$diff" -gt "0" ]; then
    echo "[SNMPd] Positive time difference, i.e the first timestamp was before the second ERROR"
    echo "        $myTime < $snmpTime  --> $diff"
#    abortWdem
#    exit 1
    echo "Nevermind"
elif [ "$diff" -lt "-2" ]; then
    echo "[SNMPd] Negative time difference, beyond 2."
    echo "        The system was too slow to respond"
    echo "        $myTime < $snmpTime  --> $diff"
#    abortWdem
    #    exit 1
    echo "Nevermind."
else 
    echo "[ TEST ] Checked difference between SNMPd and host."
    echo "         Host time = $myTime, SNMPd time=$snmpTime "
    echo "         Difference = $diff [s]"
fi


## Check last id
lastEntry=$(tail -1 /tmp/A1/counters.conf | awk -F',' '{print $1}')
lastOid="$((lastEntry + 1))"
lastOidP="$((lastEntry + 2))"

respOK=$(snmpget -Onvq -v2c -c public localhost 1.3.6.1.4.1.4171.40.$lastOid)


if [[ -z "respOK" ]]; then
    echo "[SNMP] No response when asking for a valid OID";
    echo "       Asked for 1.3.6.1.4.1.4171.40.$lastOid "
    echo "       Got: $respOK "
    abortWdem
    exit 1
else 
    echo "[ TEST ] SNMPd responded on the last valid OID"
fi

respNOK=$(snmpget -Onvq -v2c -c public localhost 1.3.6.1.4.1.4171.40.$lastOidP 2> /dev/null)

if [[ -z "respNOK" ]]; then
    echo "[SNMP] Got a response when asking for an invalid OID";
    echo "       Asked for 1.3.6.1.4.1.4171.40.$lastOidP "
    echo "       Got: |$respNOK| "
    abortWdem
    exit 1
else 
    echo "[ TEST ] SNMPd hanled a request to an invalid OID."
fi

echo "[ TEST ] Checking the LAST OID , disjunct and large"

##Check rate for last OID
rm -f /tmp/A1/rateCheck_samples.log /tmp/A1/rates.log
for k in {1..20}; do 
    snmpget -Onvq -v2c -c public localhost 1.3.6.1.4.1.4171.40.1 1.3.6.1.4.1.4171.40.$lastOid | tr '\n' ' ' | awk '{print $1," ",$2}' >> /tmp/A1/rateCheck_samples.log
    sleep 1
done

## Get the rate between samples
awk 'NR>1{print ($2-d)/($1-p)} {p=$1;d=$2}' /tmp/A1/rateCheck_samples.log > /tmp/A1/rates.log

##check if negative rate is found
negrate=$(grep '-' /tmp/A1/rates.log)
if [[ "$negrate" ]]; then
    echo "         Found negative rate, wrapp occured"
fi

## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' /tmp/A1/rates.log )

if [ -z $mvalue ]; then
    echo "[ ERROR ] mvalue does not exist, you got big problems.";
    echo "          Your data, found in rateCheck_samples.log looks like this."
    head -5 /tmp/A1/rateCheck_samples.log 
    echo "          This was generated by "
    echo " snmpget -Onvq -v2c -c public localhost 1.3.6.1.4.1.4171.40.1 1.3.6.1.4.1.4171.40.$lastOid " 
    abortWdem
    exit 1
fi


## Get counter rate
lastC=$(tail -1 /tmp/A1/counters.conf | awk -F',' '{print $2}')
pm=$(printf '\xF1')
echo "         Capacity: $lastC -- $mvalue std.dev= $stdval based on  $samples ($negs negative samples rejected)"

if [ "$lastC" -ne "$mvalue" ]; then 
    echo "[ TEST ] The calulated rate is not equal to the configured."
    echo "         Configured $lastC "
    echo "         Returned   $mvalue"
    abortWdem
    exit 1
else
    echo "[ TEST ] The returned rate matches the configured (average)"
fi

if [ "$stdval" -ne "0" ]; then
    echo "[ TEST ] The standard deviation is not zero, so there is variability"
    echo "         in the rates, there should not be. "
    abortWdem
    exit 1
else
    echo "[ TEST ] The rate does not vary (std.dev). "
fi


noIfs=$(cat /tmp/A1/counters.conf | wc -l | awk '{print $1-2}')

#echo "         We have a range 0 to $noIfs "
chkIF=$(( ( RANDOM % $noIfs )  + 1 ))

## Get counter rate
OidC=$(grep "^$chkIF," /tmp/A1/counters.conf | awk -F',' '{print $2}')


let chkOID=chkIF+1
echo "         Randomly picked to check $chkIF with $OidC";


rm -f /tmp/A1/rateCheck_samples.log
for k in {1..20}; do 
    snmpget -Onvq -v2c -c public localhost 1.3.6.1.4.1.4171.40.1 1.3.6.1.4.1.4171.40.$chkOID | tr '\n' ' ' | awk '{print $1," ",$2}' >> /tmp/A1/rateCheck_samples.log
    sleep 1
done

## Get the rate between samples
awk 'NR>1{print ($2-d)/($1-p)} {p=$1;d=$2}' /tmp/A1/rateCheck_samples.log > /tmp/A1/rates.log

##check if negative rate is found
negrate=$(grep '-' /tmp/A1/rates.log)
if [[ "$negrate" ]]; then
    echo "        Found negative rate, wrapp occured"
fi


## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' /tmp/A1/rates.log )




echo "Capacity: $OidC -- $mvalue std.dev= $stdval based on  $samples ($negs negative samples rejected)"

if [ "$OidC" -ne "$mvalue" ]; then 
    echo "[ TEST ] The calulated rate is not equal to the configured."
    echo "         Configured $OidC "
    echo "         Returned   $mvalue"
    abortWdem
    exit 1
else
    echo "[ TEST ] The returned rate matches configure (average)"
fi

if [ "$stdval" -ne "0" ]; then
    echo "[ TEST ] The standard deviation is not zero, so there is variability"
    echo "         in the rates, there should not be. "
    abortWdem
    exit 1
else
    echo "[ TEST ] The rate does not vary (std.dev). "
fi





echo "----------------------"
echo "If you gotten this far, and there are no ERRORS or issues mentioned above, its probably ok."
echo "----------------------"

sudo killall snmpd
abortWdem
 
##CLEAN UP FILES
rm -f /tmp/A1/counters.conf
rm -f /tmp/A1/rateCheck_samples.log
rm -f /tmp/A1/rates.log
rm -f /tmp/A1/snmpd.log





