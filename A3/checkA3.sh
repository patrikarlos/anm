#!/bin/bash
# Check A3 of ANM2017.
# Syntax:
# checkA3.sh <configfile> <directory containing users A3 submission>
#
#
#
# <config file> contains  the following variables
#GRAFANA_IP="127.0.0.1"
# GRAFANA_CRED="ats:atslabb00"


myConfig=$1
myBase=$2

#git log --pretty=format:'%ci %cn %H' -n 1
version='2017-10-27 17:35:39 +0200 Patrik Arlos b47eded587e5131a321190536ac9248044208560'


echo "...................................."
echo $(date) . "Starting the evaluation of A3."
echo "...................................."
echo "This is version"
echo "$version"
echo " "

if [ ! -e "$myConfig" ]; then
    echo "[ CA3: BUMMER ] " >>$myBase/test.log
    echo "[ CA3: SETUP ] Cant load the config file, $myConfig " >>$myBase/test.log
    echo "          I assume the worst, exiting." >>$myBase/test.log
    exit 1 
else 
    echo "[ CA3: SETUP ] Using $myConfig for configuration " >>$myBase/test.log
fi


source $myConfig 


echo "[ CA3: SETUP ] Using $myBase for source/storage/log" 


refdevice1='192.168.185.60'
credential_dev1="$refdevice1:1611:public"
FS=1

#abort() {
#    demDead=$(ps -elf | grep backend )
#    if [[ ! -z "$demDied" ]]; then
#	echo "[Backend] Dead OK"
#    else 
#	echo "[Backend] Still alive"
#    fi
#}

checkInfluxdb() {
    oid=$1
    chkIF=$(( oid - 1));
    echo "Checking $oid as $chkIF " >> $myBase/test.log
    rm -f $myBase/rates.log
    curl -s -G 'http://localhost:8086/query?pretty=true&u=ats&p=atslabb00' --data-urlencode "db=A3" --data-urlencode "q= SELECT value FROM rate WHERE oid = '1.3.6.1.4.1.4171.40.$oid' GROUP BY * ORDER BY DESC LIMIT 10" | jq .results  | jq  '.[]  | .series ' | jq '.[] .values' |  grep -v '"'  | grep -v '[,[]' | grep -v ']' > $myBase/rates.log
    
 
    #----
    ## Get counter rate
    OidC=$(grep "^$chkIF," $myBase/counters.conf | awk -F',' '{print $2}')
    ## Get statistics
    read mvalue stdval samples negs <<<$(awk '{ for(i=1;i<=NF;i++) if ($i>0) {sum[i] += $i; sumsq[i] += ($i)^2;} else {de++;} } END {for (i=1;i<=NF;i++) { printf "%d %d %d %d\n", sum[i]/(NR-de), sqrt((sumsq[i]-sum[i]^2/(NR-de))/(NR-de)), (NR-de), de} }' $myBase/rates.log )

    difv=$(( OidC - mvalue ))
    if [ "$difv" -lt 0 ]; then
	echo "Diff is negative, (-1) " >>$myBase/test.log
	difv=$(( -1 * difv )); 
    fi

    echo "Rates: $OidC vs $mvalue +-$stdval from $samples samples, difference $difv ." >>$myBase/test.log


    if [ "$mvalue" -ne "$OidC" ]; then 

	if [ "$difv" -lt $stdval ]; then
	    echo "The difference is $difv, less than $stdval, close enough." >>$myBase/test.log
	else
	    if [ "$difv" -lt 100 ]; then
		echo "The difference is $difv, less than 100, close enough." >>$myBase/test.log
	    else
		echo "ERROR: Requested $OidC got $mvalue, the difference is $difv" >>$myBase/test.log
		echo "       the requirement is that it has to be less than the $stdval" >>$myBase/test.log
	    fi
	fi

    else
	echo "Ok, rate matches." >>$myBase/test.log
    fi
   
}


echo "...................................." >>$myBase/test.log
echo $(date) . "Starting the evaluation of A3." >>$myBase/test.log
echo "...................................." >>$myBase/test.log


if [ ! -e $myBase/backend ]; then
    echo "[Backend] File ($myBase/backend) is missing. " >>$myBase/test.log
    echo "No point to continue." >>$myBase/test.log
    exit 1
fi

chmod u+x $myBase/backend 
if [ ! -x $myBase/backend ]; then
    echo "[Backend] File ($myBase/backend) does not have the exec bit set. " >>$myBase/test.log
    echo "No point to continue." >>$myBase/test.log
    exit 1
fi


echo "[Backend] checking for Influx credentials, usage of and usage of /tmp/A2/prober." >>$myBase/test.log

A=$(cat $myBase/backend | grep '8086')

if [ -z "$A" ]; then
    echo "ERROR" >>$myBase/test.log
    echo "[Backend] Did not detect the influx port. ($A)" >>$myBase/test.log
    echo " I assume the worst, exiting." >>$myBase/test.log
    exit 1 
fi

A=$(cat $myBase/backend | grep 'ats')
if [ -z "$A" ]; then
    echo "ERROR" >>$myBase/test.log
    echo "[Backend] Did not detect the influx username. ($A)" >>$myBase/test.log
    echo " I assume the worst, exiting." >>$myBase/test.log
    exit 1 
fi

A=$(cat $myBase/backend | grep 'atslabb00')
if [ -z "$A" ]; then
    echo "ERROR" >>$myBase/test.log
    echo "[Backend] Did not detect the influx user password ($A)" >>$myBase/test.log
    echo " I assume the worst, exiting." >>$myBase/test.log
    exit 1 
fi

A=$(cat $myBase/backend | grep 'A3')
if [ -z "$A" ]; then
    echo "ERROR" >>$myBase/test.log
    echo "[Backend] Did not detect the influx database. ($A)" >>$myBase/test.log
    echo " I assume the worst, exiting." >>$myBase/test.log
    exit 1 
fi

echo "Looking for host" >>$myBase/test.log 

lh=$(grep  localhost $myBase/backend)
lip=$(grep  127.0.0.1 $myBase/backend)

if [[ -z "$lh" && -z "$lip" ]]; then
    echo "ERROR" >>$myBase/test.log
    echo "[Backend] Did not detect the influx host ip (localhost or 127.0.0.1)" >>$myBase/test.log
    echo " $lh - $lip " >>$myBase/test.log
    echo " I assume the worst, exiting." >>$myBase/test.log
    exit 1 
fi    

A=$(cat $myBase/backend | grep '/tmp/A2/prober')
if [ -z  "$A" ]; then
    echo "ERROR" >>$myBase/test.log
    echo "[Backend] Did not detect the call for A2 prober." >>$myBase/test.log
    echo " I assume the worst, exiting." >>$myBase/test.log
    exit 1 
fi

echo "Creating a subtitue backend; with reference A2" >>$myBase/test.log
cp $myBase/backend $myBase/backend.test
sed -i 's/A2/refA2/g' $myBase/backend.test
echo "$myBase/backend.test created".  >>$myBase/test.log


if [ ! -e $myBase/dashboard.json ]; then
    echo "Error: Cant find $myBase/dashboard.json" >>$myBase/test.log
    echo "Folder contains:" >>$myBase/test.log
    ls $myBase >>$myBase/test.log
    echo "        Leaving." >>$myBase/test.log
    exit 1
fi


echo "Pre-flight check done" >>$myBase/test.log

echo "Fixing dashboard">>$myBase/test.log
randstr0=$(cat /dev/urandom | tr -dc 'a-z' | fold -w 6 | head -n 1)
randstr=$(echo "my$randstr0")

cat $myBase/dashboard.json | jq . > $myBase/bob.json
cat $myBase/bob.json | jq '.dashboard.id = null ' > $myBase/bob2.json
cat $myBase/bob2.json | jq --arg RANDSTR "$randstr" '.dashboard.title = $RANDSTR' > $myBase/bob3.json

echo  ","overwrite":false}" >> $myBase/bob3.json

echo "Pushing Dashboard" >>$myBase/test.log
resp=$(curl -s -u "$GRAFANA_CRED" -XPOST -H 'Content-Type: application/json;charset=UTF-8' -d@$myBase/bob3.json "http://$GRAFANA_IP:3000/api/dashboards/db")
echo "Grafana said: $resp" >>$myBase/test.log

##This will store data into influx.
echo "$myBase/backend.test $credential_dev1 $FS 1.3.6.1.4.1.4171.40.2 1.3.6.1.4.1.4171.40.3 1.3.6.1.4.1.4171.40.4 1.3.6.1.4.1.4171.40.5 1.3.6.1.4.1.4171.40.6 1.3.6.1.4.1.4171.40.7 1.3.6.1.4.1.4171.40.8  1.3.6.1.4.1.4171.40.18 1.3.6.1.4.1.4171.40.19 2>/dev/null > $myBase/backend.log "
 
$myBase/backend.test $credential_dev1 $FS 1.3.6.1.4.1.4171.40.2 1.3.6.1.4.1.4171.40.3 1.3.6.1.4.1.4171.40.4 1.3.6.1.4.1.4171.40.5 1.3.6.1.4.1.4171.40.6 1.3.6.1.4.1.4171.40.7 1.3.6.1.4.1.4171.40.8  1.3.6.1.4.1.4171.40.18 1.3.6.1.4.1.4171.40.19 2>/dev/null > $myBase/backend.log &
myPid=$!

##Get the current reference counters
echo "curl -s http://$refdevice1/counters.conf >  $myBase/counters.conf" >>$myBase/test.log
curl -s http://$refdevice1/counters.conf >  $myBase/counters.conf

echo "myPid = $myPid" >>$myBase/test.log

sleep 30
echo "Grab a picture" >>$myBase/test.log
echo "curl -s -u '$GRAFANA_CRED' 'http://$GRAFANA_IP:3000/render/dashboard/db/$randstr?width=1024' > $myBase/ablob.png"  >>$myBase/test.log
resp=$(curl -s -u "$GRAFANA_CRED" "http://$GRAFANA_IP:3000/render/dashboard/db/$randstr?width=1024" > $myBase/ablob.png)
echo "Grafana said $resp " >>$myBase/test.log
sleep 30 

echo "Grab a picture" >>$myBase/test.log
echo "curl -s -u '$GRAFANA_CRED' 'http://$GRAFANA_IP:3000/render/dashboard/db/$randstr?width=1024' > $myBase/ablob.png"  >>$myBase/test.log
resp=$(curl -s -u "$GRAFANA_CRED" "http://$GRAFANA_IP:3000/render/dashboard/db/$randstr?width=1024" > $myBase/ablob2.png)
echo "Grafana said $resp " >>$myBase/test.log

## GRAB A bunch of data from influxdb.. 
# curl -s -G 'http://localhost:8086/query?pretty=true&u=ats&p=atslabb00' --data-urlencode "db=A3" --data-urlencode "q= SELECT mean(value) FROM rate WHERE oid = '1.3.6.1.4.1.4171.40.2' GROUP BY * ORDER BY DESC LIMIT 10"

echo "*******abt to kill**********" >>$myBase/test.log

backprocs=$(ps -lf | grep "$myPid")
echo "****Backend****" >>$myBase/test.log
echo "myPid = $myPid"

kill -- "$myPid" > /dev/null
echo "***Killed backend***" >>$myBase/test.log
backprocs=$(ps -elf | grep "$myPid")
echo "$backprocs " >>$myBase/test.log
echo "--------------------" >>$myBase/test.log
sleep 5

leftover=$(ps -lf | grep prober )
backpid=$(ps -lf | grep prober | awk '{print $4'})
echo "Still around? : $leftover" >>$myBase/test.log
kill $backpid

echo " " ## To print buffered output. >>$myBase/test.log



echo "---Evaluate data---" >>$myBase/test.log

echo "Checking if interface 1 (oid==2) was properly handled."  >>$myBase/test.log
checkInfluxdb 2 
echo "Checking if interface 2 (oid==3) was properly handled." >>$myBase/test.log
checkInfluxdb 3
echo "Checking if interface 17 (oid==18) was properly handled."  >>$myBase/test.log
checkInfluxdb 18
echo "Checking if interface 18 (oid==19) was properly handled." >>$myBase/test.log
checkInfluxdb 19




echo "Removing my dashboard: http://$GRAFANA_IP:3000/api/dashboards/db/$randstr   " >>$myBase/test.log
resp=$(curl -s -u "$GRAFANA_CRED" -XDELETE -H 'Content-Type: application/json;charset=UTF-8' "http://$GRAFANA_IP:3000/api/dashboards/db/$randstr")
echo "Grafana said: $resp" >>$myBase/test.log

## Get a comparitative graph
convert  $myBase/ablob.png  $myBase/ablob2.png -geometry 750x750 -append  $myBase/result.png

echo "The comparative image is found here $myBase/result.png " >>$myBase/test.log



#influxdb
#auth <:>
#create database "A3"
#create USER ats WITH PASSWORD 'atslabb00'
#grant ALL ON "A3" to "ats"
