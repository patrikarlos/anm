#!/bin/bash

##Check snmpd.config

abortWdem() {
demDied=$(cat /tmp/A1/snmpd.log | grep 'Received TERM or STOP signal...  shutting down')
if [[ ! -z "$demDied" ]]; then
    echo "[SNMPd] Died OK";
else 
    echo "[SNMPd] did not report its death correctly, or it did not die (did it start?)"
fi
}


echo "...................................."
echo $(date) . "Starting the evaluation of A1."
echo "...................................."

if pidof -x "snmpd" >/dev/null; then
    echo "[SNMPd] Allready running"
    echo "        Leaving."
    exit 1
fi

lh=$(cat snmpd.conf  | grep agentAddress | grep  localhost)
lip=$(cat snmpd.conf  | grep agentAddress | grep  127.0.0.1)
lprotport=$(cat snmpd.conf  | grep agentAddress | grep  udp:161)

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
    echo "[SNMPd] MISSING PATH will not work";
    exit 1
fi







##Create an counters.conf


noIfs=$(( ( RANDOM % 10 )  + 5 ))
myif=1
echo "Creating counters.conf, with $noIfs random interfaces. "
rm /tmp/A1/counters.conf
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
sudo snmpd -f -c snmpd.conf -C -a -Lf /tmp/A1/snmpd.log &



##Initial test.
myTime=$(date +%s)
snmpTime=$(snmpget -Onvq -v1 -c public localhost 1.3.6.1.4.1.4171.40.1)

diff="$((myTime-snmpTime))"

if [ "$diff" -gt "0" ]; then
    echo "[SNMPd] Positive time difference, i.e the first timestamp was before the second ERROR"
    echo "        $myTime < $snmpTime  --> $diff"
    abortWdem
    exit 1
elif [ "$diff" -lt "-2" ]; then
    echo "[SNMPd] Negative time difference, beyond 2."
    echo "        The system was too slow to respond"
    echo "        $myTime < $snmpTime  --> $diff"
    abortWdem
    exit 1
else 
    echo "[SNMPd] hopefully within bounds, t0= $myTime, t1=$snmpTime  --> $diff"
fi


## Check last id
lastEntry=$(tail -1 /tmp/A1/counters.conf | awk -F',' '{print $1}')
lastOid="$((lastEntry + 1))"
lastOidP="$((lastEntry + 2))"

respOK=$(snmpget -Onvq -v1 -c public localhost 1.3.6.1.4.1.4171.40.$lastOid)


if [[ -z "respOK" ]]; then
    echo "[SNMP] No response when asking for a valid OID";
    echo "       Asked for 1.3.6.1.4.1.4171.40.$lastOid "
    echo "       Got: $respOK "
    abortWdem
    exit 1
else 
    echo "[SNMP] Got a response on the last valid OID"
fi

respNOK=$(snmpget -Onvq -v1 -c public localhost 1.3.6.1.4.1.4171.40.$lastOidP 2> /dev/null)

if [[ -z "respNOK" ]]; then
    echo "[SNMP] Got a response when asking for an invalid OID";
    echo "       Asked for 1.3.6.1.4.1.4171.40.$lastOidP "
    echo "       Got: |$respNOK| "
    abortWdem
    exit 1
else 
    echo "[SNMP] Seems to handle invalid OIDs"
fi

echo "Checking the LAST OID , disjunct and large"

##Check rate for last OID
rm rateCheck_samples.log
for k in {1..10}; do 
    snmpget -Onvq -v1 -c public localhost 1.3.6.1.4.1.4171.40.$lastOid >> rateCheck_samples.log
    sleep 1
done

## Get the rate between samples
awk 'NR>1{print $1-p} {p=$1}' rateCheck_samples.log > rates.log

##check if negative rate is found
negrate=$(grep '-' rates.log)
if [[ "$negrate" ]]; then
    echo "Found negative rate, wrapp occured"
fi


## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' rates.log )


## Get counter rate
lastC=$(tail -1 /tmp/A1/counters.conf | awk -F',' '{print $2}')
pm=$(printf '\xF1')
echo "Capacity: $lastC -- $mvalue std.dev= $stdval based on  $samples ($negs negative samples rejected)"

if [ "$lastC" -ne "$mvalue" ]; then 
    echo "[SNMP] The calulated rate is not equal to the configured."
    echo "       Configured $lastC "
    echo "       Returned   $mvalue"
    abortWdem
    exit 1
else
    echo "[SNMP] The returned rate matches configure (average)"
fi

if [ "$stdval" -ne "0" ]; then
    echo "[SNMP] The standard deviation is not zero, so there is variability"
    echo "       in the rates, there should not be. "
    abortWdem
    exit 1
else
    echo "[SNMP] The rate does not vary"
fi


noIfs=$(cat counters.conf | wc -l | awk '{print $1-2}')

echo "We have a range 0 to $noIfs "
chkIF=$(( ( RANDOM % $noIfs )  + 1 ))

## Get counter rate
OidC=$(grep "^$chkIF," /tmp/A1/counters.conf | awk -F',' '{print $2}')

echo "Will check $chkIF with $OidC";
let chkOID=chkIF+1


rm rateCheck_samples.log
for k in {1..10}; do 
    snmpget -Onvq -v1 -c public localhost 1.3.6.1.4.1.4171.40.$chkOID >> rateCheck_samples.log
    sleep 1
done

## Get the rate between samples
awk 'NR>1{print $1-p} {p=$1}' rateCheck_samples.log > rates.log

##check if negative rate is found
negrate=$(grep '-' rates.log)
if [[ "$negrate" ]]; then
    echo "Found negative rate, wrapp occured"
fi


## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' rates.log )




echo "Capacity: $OidC -- $mvalue std.dev= $stdval based on  $samples ($negs negative samples rejected)"

if [ "$OidC" -ne "$mvalue" ]; then 
    echo "[SNMP] The calulated rate is not equal to the configured."
    echo "       Configured $OidC "
    echo "       Returned   $mvalue"
    abortWdem
    exit 1
else
    echo "[SNMP] The returned rate matches configure (average)"
fi

if [ "$stdval" -ne "0" ]; then
    echo "[SNMP] The standard deviation is not zero, so there is variability"
    echo "       in the rates, there should not be. "
    abortWdem
    exit 1
else
    echo "[SNMP] The rate does not vary"
fi





echo "----------------------"
echo "If you gotten this far, and there are no ERRORS or issues mentioned above, its probably ok."
echo "----------------------"
sudo killall snmpd
abortWdem





