checkA1.sh
==========

Introduction
------------

Script expects that solution is found in /tmp/A1.

Checks that the correct files exists; 
/tmp/A1/snmpd.conf
/tmp/A1/subagent

Checks that snmpd.conf contains the required information, and does not
contain information that would prevent it from working correctly. 

Generates a counter.conf and launches the snmpd. 


Test Sequence
-------------

Probes the launched agent. 
1. Checks that the time reported does not differ from the computer time, should be the same as it runs on the same device. Accepted range of values is 0<X<-1. 
2. Checks that the agent handles the last interface provided in the counter.conf file, i.e. answers the request. 
3. Checks that the agent handles an request to an interface that DOES not exist.
4. Checks that the agent handles requests to two different OIDs, first and last.
   4.a Get the first and last OID, clean data and store to file. 
   4.b Based on the log; calculate the rate change between the rows and columns
       in the file. As the test does not handle wraps, it just registers them.
   4.c Filter out the time value, and calculate statistics from the rates 
       (average, std.dev).
   4.d If no average is obtained, this indicate a problem/Error.
5. Compare the average to the rate in counters.conf, should be identical.
6. If the std.dev. is not zero (probably caught by average), ERROR 
7. Checks that the agent handles requests to two different OIDs, fist and 
   random. 
   7.a Get the first and random OID, clean data and store to file. 
   7.b Based on the log; calculate the rate change between the rows and columns
       in the file. As the test does not handle wraps, it just registers them.
   7.c Filter out the interface value, and calculate statistics from the rates 
       (average, std.dev).
   7.d If no average is obtained, this indicate a problem/Error.
8. Compare the average to the rate in counters.conf, should be identical.
9. If the std.dev. is not zero (probably caught by average), ERROR 



