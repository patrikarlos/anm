checkA3.sh
==========

Introduction
------------

Test A3. Needs a file (configfile) with two variables
GRAFANA_IP="theIP"
GRAFANA_CRED="user:passwd"

As th

Usage
-----

./checkA3.sh <configfile> <solution-folder> 




Test Sequence
-------------

Initially test if the config exist, if not BUMMER cant test. 

1. Check if the solution-folder(SF) contains the backend (solution), if not 
   ERROR. 

2. Change the executable bit, and check that its set. If not ERROR. 
(should not be a problem as we set it on the line above, if it is then 
it indicates that we cant write the file/SF folder. )

3. Check usage of /tmp/A2/prober and Influx credentials/usage.
   3a. Check that the backend contains '8086', i.e. the InfluxDB port, if 
       not ERROR. 
   3b. Check that the backend contains 'ats', i.e. the InfluxDB username, 
       if not ERROR. 
   3c. Check that the backend contains 'atslabb00', i.e. the InfluxDB 
       password, if not ERROR. 
   3d. Check that the backend contains 'A3', i.e. the InfluxDB database, 
       if not ERROR. 
   3e. Check that the backend contains either 'localhost' or '127.0.0.1', 
       if not ERROR. 

Make a copy of backend (backend.test), and change the copy as to use a 
reference A2 solution as prober. 

4. Check if dashboard.json exist, if not ERROR. 

Generate a random dashboard title, create a copy of the dashboard and 
replace the existing title with the random title (bob3.json). 

Push the dashboard (copy with new title) to Grafana. 

Start the backend.test, check interfaces 2--8, 18--19. 

Grab a copy of the counters.conf of the probed device. 

Grab a snapshot (picture) of the Grafana dashboard (showing the rates). 
Sleep 30s, and grab another snapshot (picture) of the Grafana dashboard.

Stop the backend, and make sure it terminates correctly. 

Evaluate the data, for the different interfaces. 

5. Check interface  1,2,17 and 18 (OID==2,3,18 and 19), 
   Grab data from InfluxDB for OID 2, filter and store to rates.log.
   Calculate the average(M) and std.dev(STD). 
   Check if |Counter.Rate-M| > 100, ERROR. 
   	 if Counter.Rate == M, the OK
	 if | Counter.Rate - M | < STD, then OK


Remove the Grafana dashboard. 

Combine the pictures into one picture, showing the rates before and after. 
Visually inspect the result.png. 
