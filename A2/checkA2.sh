#!/bin/bash

echo "Checking Correct sample count"

##prober <Agent IP:port:community> <sample frequency> <samples> <OID1> <OID2> …….. <OIDn>

Ns=$(( ( RANDOM % 10 )  + 3 ));
Fs=1;
chkIF=2;
ooid=$(( chkIF + 1));



# echo "Will collect $Ns at $Fs Hz, from $ooid ($chkIF) "
# ./prober 127.0.0.1:1611:public $Fs $Ns 1.3.6.1.4.1.4171.40.$ooid > data

# rateCnt=$(cat data | wc -l)
# sampleCnt="$((rateCnt + 1))"

# if [ "$Ns" -ne "$sampleCnt" ]; then 
#     echo "Error: Requested $Ns samples; got $sampleCnt". 
#     exit 1
# else 
#     echo " Got $Ns samples."
# fi

# echo "Checking the samplerate"


# ## Get the rate between samples
# awk 'NR>1{print $1-p} {p=$1}' data > Trates.log

# ## Get statistics
# read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' Trates.log )

# echo "Time: $mvalue +-$stdval from $samples"

# if [ "$mvalue" -ne "$Fs" ]; then 
#     echo "Error: Requested $Fs got $mvalue Hz"
#     exit 1
# else 
#     echo "OK; Sample rate seems reasonable."
# fi

# ## Get the rate between samples
# echo "Checking datarate" 
# awk '{print $3}' data > rates.log

# ## Get counter rate
# OidC=$(grep "^$chkIF," /tmp/refA1/counters.conf | awk -F',' '{print $2}')
# ## Get statistics
# read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' rates.log )

# echo "Rates: $mvalue +-$stdval from $samples"

# if [ "$mvalue" -ne "$OidC" ]; then 
#     echo "Error: Requested $OidC got $mvalue Hz"
#     exit 1
# else
#     echo "Ok, rate 1."
# fi


# echo "Collecting high rate"
# ./prober 127.0.0.1:1611:public $Fs $Ns 1.3.6.1.4.1.4171.40.18 > data

# awk '{print $3}' data > rates.log

# chkIF=17;## Get counter rate
# OidC=$(grep "^$chkIF," /tmp/refA1/counters.conf | awk -F',' '{print $2}')

# ##check if negative rate is found
# negrate=$(grep '-' rates.log)
# if [[ "$negrate" ]]; then
#     echo "Found negative rate, wrapp occured"
# fi



# ## Get statistics
# read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' rates.log )

# echo "Rates: $mvalue +-$stdval from $samples vs $OidC"

# if [ "$mvalue" -ne "$OidC" ]; then 
#     echo "Error: Requested $OidC got $mvalue Hz"
#     exit 1
# else
#     echo "Ok, rate high"
# fi


# echo "Checking SNMP requests"
# ## Get snmp requests
# sudo tcpdump -c 10 -ttt -n -i br0 ip dst 192.168.184.40 and udp and dst port 161 > blob &
# echo "tcpdump on"
# sleep 3

#./prober 192.168.184.40:161:public 1 10 1.3.6.1.2.1.2.2.1.10.3


# echo "Requests sent, logged, now validating" 

# read avg stdev samps <<<$(awk '{print $1}' blob | awk -F':' 'NR>1{print $3}' | awk '{sum+=$1;sumsq+=($1)^2;n++;} END {printf "%f %f %d\n",sum/n, sqrt((sumsq-sum^2/(n))/(n)),n} ' )

# echo "Mean: $avg Stddev: $stdev N: $samps"
# stdCheck=$(echo $stdev'<0.1'|bc -l)

# if [ "$stdCheck" -eq "0" ]; then
#     echo "The std.dev is a bit high, $stdev  vs required 0.1"
#     echo "Target average was 1.0 s yours was $avg s".
#     exit 1
# else
#     echo "Nice request stability; $stdev vs required 0.1"
# fi


# echo "Checking that the prober contains ALL OIDS in one request."
# sudo tcpdump -c 1 -ttt -n -i br0 ip dst 192.168.184.40 and udp and dst port 161 > blob &
# echo "tcpdump on"
# sleep 3

# ./prober 192.168.184.40:161:public 1 1 1.3.6.1.2.1.2.2.1.10.3 1.3.6.1.2.1.2.2.1.16.3 1.3.6.1.2.1.2.2.1.10.4 1.3.6.1.2.1.2.2.1.16.4

# sleep 3
# echo "tcp done, we hope". 

# awk '{out=""; for(i=7;i<=NF;i++){printf "%s\n",$i};}' blob > oidsInReq

# if [ $(diff myOids oidsInReq|wc -l) -ne 0 ]; then 
#     echo "There is a discrepancy betweeen what was requested, and was detected"
#     exit 1
# else
#     echo "All OIDS are present, no extra no missing."
# fi



# echo "Checking SNMP requests, against not so nice device (delay)"
# ## Get snmp requests
# sudo tcpdump -c 10 -ttt -n -i lo ip dst 127.0.0.1 and udp and dst port 1611 > blob &
# echo "tcpdump on"
# sleep 3

# ./prober 127.0.0.1:1611:public 1 10 1.3.6.1.4.1.4171.40.19

# echo "Requests sent, logged, now validating" 

# read avg stdev samps <<<$(awk '{print $1}' blob | awk -F':' 'NR>1{print $3}' | awk '{sum+=$1;sumsq+=($1)^2;n++;} END {printf "%f %f %d\n",sum/n, sqrt((sumsq-sum^2/(n))/(n)),n} ' )

# echo "Mean: $avg Stddev: $stdev N: $samps"
# stdCheck=$(echo $stdev'<0.1'|bc -l)

# if [ "$stdCheck" -eq "0" ]; then
#     echo "The std.dev is a bit high, $stdev  vs required 0.1"
#     echo "Target average was 1.0 s yours was $avg s".
#     exit 1
# else
#     echo "Nice request stability; $stdev vs required 0.1"
# fi


echo "Checking SNMP requests, against not so nice device (bad response)"
## Get snmp requests
sudo tcpdump -c 10 -ttt -n -i lo ip dst 127.0.0.1 and udp and dst port 1611 > blob &
echo "tcpdump on"
sleep 3

./prober 127.0.0.1:1611:public 1 10 1.3.6.1.4.1.4171.40.20

echo "Requests sent, logged, now validating" 

read avg stdev samps <<<$(awk '{print $1}' blob | awk -F':' 'NR>1{print $3}' | awk '{sum+=$1;sumsq+=($1)^2;n++;} END {printf "%f %f %d\n",sum/n, sqrt((sumsq-sum^2/(n))/(n)),n} ' )

echo "Mean: $avg Stddev: $stdev N: $samps"
stdCheck=$(echo $stdev'<0.1'|bc -l)

if [ "$stdCheck" -eq "0" ]; then
    echo "The std.dev is a bit high, $stdev  vs required 0.1"
    echo "Target average was 1.0 s yours was $avg s".
    exit 1
else
    echo "Nice request stability; $stdev vs required 0.1"
fi

