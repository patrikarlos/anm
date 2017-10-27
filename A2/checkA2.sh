#!/bin/bash

##VARIABLES; must be filled correctly

internetNIC=br0


##
refdevice1='192.168.185.60'
refdevice2='192.168.184.40'
credential_dev1="$refdevice1:1611:public"
credential_dev2="$refdevice2:161:public"

#git log --pretty=format:'%ci %cn %H' -n 1
version='2017-10-27 08:52:49 +0200 Patrik Arlos 5f91e6cb43b9e9fe0c2e2a988adc4e3b2e244ac9'



echo "...................................."
echo $(date) . "Starting the evaluation of A2."
echo "...................................."
echo "This is version"
echo "$version"
echo " "

echo "Checking Correct sample count"
echo "Working with this;"
printf "\t refdevice1 $refdevice1 \n";
printf "\t refdevice2 $refdevice2 \n";
printf "\t credref1   $credential_dev1 \n";
printf "\t credref2   $credential_dev2 \n";




##prober <Agent IP:port:community> <sample frequency> <samples> <OID1> <OID2> …….. <OIDn>

Ns=$(( ( RANDOM % 10 )  + 3 ));
Fs=1;
chkIF=2;
ooid=$(( chkIF + 1));



echo "Will collect $credential_dev1  $Ns at $Fs Hz, from $ooid ($chkIF) "
echo "Running:"
echo "/tmp/A2/prober $credential_dev1 $Fs $Ns 1.3.6.1.4.1.4171.40.$ooid > /tmp/A2/data "

/tmp/A2/prober $credential_dev1 $Fs $Ns 1.3.6.1.4.1.4171.40.$ooid > /tmp/A2/data

rateCnt=$(cat /tmp/A2/data | wc -l)
sampleCnt="$((rateCnt))"

if [ "$Ns" -ne "$sampleCnt" ]; then 
    echo "Error: Requested $Ns samples; got $sampleCnt". 
    echo "/tmp/A2/data"
    cat /tmp/A2/data
    exit 1
else 
    echo " Got $Ns samples."
fi

echo " "
echo "Checking: Sample rate => "


## Get the rate between samples
awk 'NR>1{print $1-p} {p=$1}' /tmp/A2/data > /tmp/A2/Trates.log

## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' /tmp/A2/Trates.log )

echo "Time: $mvalue +-$stdval from $samples samples. "

if [ "$mvalue" -ne "$Fs" ]; then 
    echo "Error: Requested $Fs got $mvalue bps"
    exit 1
else 
    echo "OK; Sample rate seems reasonable."
fi

## Get the rate between samples
echo " "
echo "Checking data rate (random) " 
awk '{print $3}' /tmp/A2/data > /tmp/A2/rates.log


##Get the current reference counters
echo "curl -s http://$refdevice1/counters.conf >  /tmp/A2/counters.conf"
curl -s http://$refdevice1/counters.conf >  /tmp/A2/counters.conf

## Get counter rate
OidC=$(grep "^$chkIF," /tmp/A2/counters.conf | awk -F',' '{print $2}')
## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' /tmp/A2/rates.log )

echo "Rates: $mvalue +-$stdval from $samples"

if [ "$mvalue" -ne "$OidC" ]; then 
    echo "Error: Requested $OidC got $mvalue du/tu"
    echo "this is your data."
    head /tmp/A2/data
    exit 1
else
    echo "Ok, rate 1."
fi

echo " "
echo "Checking that we can atleast manage 2Hz"
echo "Running; /tmp/A2/prober $credential_dev1 2 20 1.3.6.1.4.1.4171.40.$ooid > /tmp/A2/fastprobe "

startTime=$(date +%s)
/tmp/A2/prober $credential_dev1 2 20 1.3.6.1.4.1.4171.40.$ooid > /tmp/A2/fastprobe
endTime=$(date +%s)

duration=$((endTime-startTime))
echo "That should have taken (approx) 10s. It took, $endTime-$startTime = $duration s. "

if [[ "$duration" -lt 9 ]]; then
    echo "Error: To send 20 requests at 2Hz should have taken arround 10s, you did it in $duration s". 
    echo "Here is a log of your output"
    head /tmp/A2/fastprobe
    exit 1
else
    echo "OK"
fi













echo " "
echo "Checking: data rate (high) "
echo "/tmp/A2/prober $credential_dev1 $Fs $Ns 1.3.6.1.4.1.4171.40.18 > /tmp/A2/data" 

/tmp/A2/prober $credential_dev1 $Fs $Ns 1.3.6.1.4.1.4171.40.18 > /tmp/A2/data

echo "Got " $(wc -l /tmp/A2/data) " samples "

awk '{print $3}' /tmp/A2/data > /tmp/A2/rates.log

chkIF=17;## Get counter rate
OidC=$(grep "^$chkIF," /tmp/A2/counters.conf | awk -F',' '{print $2}')

##check if negative rate is found
negrate=$(grep '-' /tmp/A2/rates.log)
if [[ "$negrate" ]]; then
    echo " (wrap) "
    echo " ERROR: Your solution does not handle 64bit counters wrapping."
    echo " "
    exit 1
fi



## Get statistics
read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' /tmp/A2/rates.log )

echo "Rates: $mvalue +-$stdval from $samples vs $OidC , with $negs negative rates."

if [ "$mvalue" -ne "$OidC" ]; then 
    echo "Error: Requested $OidC got $mvalue Hz"
    exit 1
else
    echo "Ok, rate high"
fi

echo ""
echo "Checking:  Requests, against a -REAL- device. "
## Get snmp requests
sudo tcpdump -c 10 -ttt -n -i $internetNIC ip dst $refdevice2 and udp and dst port 161 > /tmp/A2/blob &
echo "tcpdump on"
sleep 3

echo "Running /tmp/A2/prober $credential_dev2 1 10 1.3.6.1.2.1.2.2.1.10.3" 
/tmp/A2/prober $credential_dev2 1 10 1.3.6.1.2.1.2.2.1.10.3

printf "Requests sent, logged, validating\n" 

read avg stdev samps <<<$(awk '{print $1}' /tmp/A2/blob | awk -F':' 'NR>1{print $3}' | awk '{sum+=$1;sumsq+=($1)^2;n++;} END {printf "%f %f %d\n",sum/n, sqrt((sumsq-sum^2/(n))/(n)),n} ' )

printf "Inter request time; Mean: $avg Stddev: $stdev N: $samps"
stdCheck=$(echo $stdev'<0.1'|bc -l)

if [ "$stdCheck" -eq "0" ]; then
    echo "The std.dev is a bit high, $stdev  vs required 0.1"
    echo "Target average was 1.0 s yours was $avg s".
    exit 1
else
    echo "Nice request stability; $stdev vs required 0.1"
fi


printf "Checking that the prober contains ALL OIDS in one request."
sudo tcpdump -c 1 -ttt -n -i $internetNIC ip dst $refdevice2 and udp and dst port 161 > /tmp/A2/blob &
echo "tcpdump on"
sleep 3

echo ".1.3.6.1.2.1.1.3.0" > /tmp/A2/myOids
echo ".1.3.6.1.2.1.2.2.1.10.3" >> /tmp/A2/myOids
echo ".1.3.6.1.2.1.2.2.1.16.3" >> /tmp/A2/myOids
echo ".1.3.6.1.2.1.2.2.1.10.4" >> /tmp/A2/myOids
echo ".1.3.6.1.2.1.2.2.1.16.4" >> /tmp/A2/myOids

/tmp/A2/prober $credential_dev2 1 1 1.3.6.1.2.1.2.2.1.10.3 1.3.6.1.2.1.2.2.1.16.3 1.3.6.1.2.1.2.2.1.10.4 1.3.6.1.2.1.2.2.1.16.4

sleep 3
echo "tcp done, we hope". 

awk '{out=""; for(i=7;i<=NF;i++){printf "%s\n",$i};}' /tmp/A2/blob > /tmp/A2/oidsInReq

if [ $(diff /tmp/A2/myOids /tmp/A2/oidsInReq|wc -l) -ne 0 ]; then 
    echo "There is a discrepancy betweeen what was requested, and was detected"
    exit 1
else
    echo "All OIDS are present, no extra no missing."
fi


echo " "
echo "Checking SNMP requests, against not so nice device (delay)"
## Get snmp requests
echo "Running "
echo "tcpdump -c 10 -ttt -n -i $internetNIC ip dst $refdevice1 and udp and dst port 1611 > /tmp/A2/blob_delay" 
sudo tcpdump -c 10 -ttt -n -i $internetNIC ip dst $refdevice1 and udp and dst port 1611 > /tmp/A2/blob_delay &
echo "tcpdump on"
sleep 3

echo "/tmp/A2/prober $credential_dev1 1 10 1.3.6.1.4.1.4171.40.19"
/tmp/A2/prober $credential_dev1 1 10 1.3.6.1.4.1.4171.40.19

echo "blob_delay size:  " $(wc -l /tmp/A2/blob_delay) " lines"
echo "Requests sent, logged, now validating" 

##Wait for file to fill, or quit. 
timeOut=0
while [ ! -s /tmp/A2/blob_delay ]; do
    fs=$(wc -c /tmp/A2/blob_delay)
    echo $( date +"%Y-%M-%d %H:%m:%S") " Waiting [$timeOut] for trace to arrive, current $fs bytes" 
    sleep 1
    ((timeOut++))

    if [[ "$timeOut" -gt "10" ]]; then
	echo $( date +"%Y-%M-%d %H:%m:%S") " Waited long enough, giving up."
	echo " ERROR did not get packets in trace file within $timeOut s. "
	exit 1
    fi
done



read avg stdev samps <<<$(awk '{print $1}' /tmp/A2/blob_delay | awk -F':' 'NR>1{print $3}' | awk '{sum+=$1;sumsq+=($1)^2;n++;} END {printf "%f %f %d\n",sum/n, sqrt((sumsq-sum^2/(n))/(n)),n} ' )

echo "Mean: $avg Stddev: $stdev N: $samps"
stdCheck=$(echo $stdev'<0.1'|bc -l)

if [ "$stdCheck" -eq "0" ]; then
    echo "The std.dev is a bit high, $stdev  vs required 0.1"
    echo "Target average was 1.0 s yours was $avg s".
    exit 1
else
    echo "Nice request stability; $stdev vs required 0.1"
fi


echo "Checking SNMP requests, against not so nice device (bad response)"
## Get snmp requests
sudo tcpdump -c 10 -ttt -n -i $internetNIC ip dst $refdevice1 and udp and dst port 1611 > /tmp/A2/blob &
echo "tcpdump on"
sleep 3

/tmp/A2/prober $credential_dev1 1 10 1.3.6.1.4.1.4171.40.20

echo "Requests sent, logged, now validating" 

read avg stdev samps <<<$(awk '{print $1}' /tmp/A2/blob | awk -F':' 'NR>1{print $3}' | awk '{sum+=$1;sumsq+=($1)^2;n++;} END {printf "%f %f %d\n",sum/n, sqrt((sumsq-sum^2/(n))/(n)),n} ' )

echo "Mean: $avg Stddev: $stdev N: $samps"
stdCheck=$(echo $stdev'<0.1'|bc -l)

if [ "$stdCheck" -eq "0" ]; then
    echo "The std.dev is a bit high, $stdev  vs required 0.1"
    echo "Target average was 1.0 s yours was $avg s".
    exit 1
else
    echo "Nice request stability; $stdev vs required 0.1"
fi


echo "---------------------------------"
echo "If no issues poped up.. :thumbsup:"
echo "---------------------------------"

#rm /tmp/A2/blob /tmp/A2/counters.conf /tmp/A2/data /tmp/A2/myOids /tmp/A2/oidsInReq /tmp/A2/rates.log /tmp/A2/Trates.log
