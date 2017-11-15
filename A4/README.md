checkA3.sh
==========

Introduction
------------

Test A4, requires an interface name that will observe traffic going to 
and from the trap reciver. 



Usage
-----

./checkA4.sh <solution-folder> 




Test Sequence
-------------

Check that snmptrapd is not running, if so leave. 

1. Check that snmptrapd.conf exist, if not ERROR. 
2. Check that traphandler exist, if not ERROR. 
3. Check that getStatus.php exist, if not ERROR. 
4. Check that getTrapR.php exist, if not ERROR. 
5. Check that setTrapR.php exist, if not ERROR. 
6. Check that config.php exist, if not ERROR. 

7. Check that the snmptrapd.conf does not listen to localhost, if so ERROR.
8. Check that the snmptrapd.conf does not listen to 127.0.0.1, if so ERROR.
9. Check that the snmptrapd.conf does listen to port 50162, if not ERROR.

10. Check that the snmptrapd.conf contains a reference to traphandler, if not 
    ERROR (as it will not call the solution). 

Checking that disableAuthorization is enabled, if so nice. If not, might be 
challenging. 

Start snmptrapd based on the snmptrapd.conf, log to snmptrapd.log, store the 
PID of snmptrapd. 

Start the Webserver, based on the PHP built in server. Launch on 
127.0.0.1:8000 and log to webserver.log, store the PID of PHP.

Wait 10s for both servers to start properly. 

11. Check that webserver responds  with 'FALSE' to the first getStatus.php
    request. If not, ERROR.

12. Check that the webserver responds with Ok when setting trap receiver.
    If not, log it for evaluation later. 

13. Check that the webserver responds with the correct information when 
    asked for the trap reciver. If not, log it for evaluation later. 

14. Check that the getStatus responds with FALSE, as no traps should have
    received. If not ERROR

Send a trap, bubbly.bth.se goes to 1.  Sleep 1s, as to give the trap receiver time 
to work.

15. Check that webserver responds,
    15a. If with FALSE, then ERROR as a trap has been sent.
    15b. If the response does not contain bubbly.bth.se and '1', then ERROR.

Send a trap, trouble.bth.se goes to 1, sleep 1s. 

16. Check that webserver responds,
    16a. If with FALSE, then ERROR as a trap has been sent.
    16b. If the response does not contain bubbly.bth.se and '1', then ERROR.

Now we expect to catch an trap from the solution, start tcpdump, log one packet
filter out packets to the trap receiver (192.168.184.1:udp:161)

Send a trap, www.bth.se goes to 3 (ERROR, should trigger a trap directly),
sleep 1s.

17. Check that webserver responds,
    15a. If with ERROR, then ERROR (not expected, error code is 3 not the 
    	 string ERROR). 
    15b. If the response does not contain www.bth.se and '3', then ERROR.


18. Check that we caught a trap.
    While blob (tcpdump log file) is zero, sleep 1s, if checked 10 times then 
    ERRROR, the trap should have been sent directly waiting 10s is too long. 
    Check the data in blob. 
    	  We expect three strings, if any is empty ERROR.
	  check that '...41717.20==*www.bth.se* ' is either in the first or 
	  second OID, if not ERRROR.
    Extract the time val (not checked). 

Put www.bth.se back to normal mode (0), no trap to be received.


19. Check that webserver responds,
    19a. If with ERROR, then ERROR (not expected)
    19b. If the response does not contain www.bth.se and '3', then ERROR.


20. Check if we caught a trap (we should not)
    While blob (tcpdump log file) is zero, sleep 1s, if checked 5 times then 
    kill tcpdump 
    Check if there is any data in blob, if greater than 20 byters, ERROR.

DANGER devices

Set (first device) bubbly.bth.se into danger, wait 1s. 

21. Check that the webserver response.
    21a. If it responds FALSE (probably not caught as we grep for bubbly), 
    but if so ERROR:
    21b. If the response does not contain 'bubbly.bth.se' and '2' ERROR.


Start tcpdump and set (second device) trouble.bth.se into danger, wait 1s.

22. Check that the webserver response.
    22a. If it responds FALSE (probably not caught as we grep for trouble), 
    but if so ERROR:
    22b. If the response does not contain 'trouble.bth.se' and '2' ERROR.

23. Check that BOTH devices are present in the web server response.
    Grep for '| 2 |', will select the status column, and count the lines. 
    If not two lines, ERROR. 
    
24. Check that we caught a trap.
    While blob (tcpdump log file) is zero, sleep 1s, if checked 10 times then 
    ERRROR, the trap should have been sent directly waiting 10s is too long. 

25. Check the content of blob (OIDS sent to receiver)
    Create a file with all the expected OIDS (myOids)
    Refine the content in blob to match that of the myOids file, so we will 
    have two files myOids and oidsInReq, they should be similar in content.
    Assumes that the oids in request are in incremental order...
    Do a diff between the files and count the number of lines, this should be 0
    as the should be identical wrt. the included OIDs. If not ERROR.

26. Check that bubbly and trouble are present in the trap received, both 
    are required, if not ERROR.

Start tcpdump and set (third device) www.bth.se into danger, wait 1s.

27. Check that the webserver response for www is correct.
    27a. If it responds FALSE (probably not caught as we grep for www), 
    but if so ERROR:
    27b. If the response does not contain 'www.bth.se' and '2' ERROR.

28. Check that ALL THREE devices are present in the web server response.
    Grep for '| 2 |', will select the status column, and count the lines. 
    If not three lines, ERROR. 

29. Check the content of blob (OIDS sent to receiver)
    Append the new expected OIDS to myOids, refine the content in blob to match 
    that of the myOids file, so we will have two files myOids and oidsInReq, 
    they should be similar in content. Assumes that the oids in request are in 
    incremental order. Do a diff between the files and count the number of 
    lines, this should be 0 as the should be identical wrt. the included OIDs. 
    If not ERROR


Danger test is over, check if the system appends danger information to error 
traps (should not). 

Start tcpdump and set Jupiter.bth.se to 3, wait 1s.

30. Check that webserver responds,
    30a. If with ERROR, then ERROR (not expected, error code is 3 not the 
    	 string ERROR). 
    30b. If the response does not contain jupiter.bth.se and '3', then ERROR.


31. Check that we caught a trap.
    While blob (tcpdump log file) is zero, sleep 1s, if checked 10 times then 
    ERRROR, the trap should have been sent directly waiting 10s is too long. 
    Check the data in blob. 
    	  We expect three strings, if any is empty ERROR.
	  check that '...41717.20==*jupiter.bth.se* ' is either in the first or 
	  second OID, if not ERRROR.
    Extract the time val (not checked). 

Put www.bth.se back to normal mode (0), no trap to be received.


Test is over. 
