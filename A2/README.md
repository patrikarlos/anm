checkA2.sh
==========

Introduction
------------

internetNIC needs to be updated to match the interface that connects to the 
Internet, i.e. where your default router is found. 

Script expects that the solution is found in /tmp/A2




Test Sequence
-------------

1. Check that /tmp/A2/prober exist. If not, ERROR.
2. Check that /tmp/A2/prober is executable. If not, ERROR.
3. Check that if N samples are requested N are returned. If not, ERROR.
4. Check that the obtained sample rate matches the requested. 
5. Check that the data rate matches the counter.conf in the probed device.
6. Check that the prober can handle Fs=2Hz, run 20 samples at 2Hz. This should
   take ~10s, if its <9 then ERROR. 
7. Check that the prober handles a high data rate.
   7a. If the solution returns a negative rate, ERROR. 
   7b. Compare that the obtained rates does not differ from the expected rate.
       If any line does not match, ERROR. 
       This means the solution needs to handle both data and time rate. 
8. Check that the solution can handle a REAL device. This is done by checking
   that the packets leaving the system has the correct inter departure time. 
   The value should be 1s, accepted std.dev 0.1s. If not, ERROR. 
9. Check that the solution handled multiple OIDs correctly, i.e. all OIDs are 
   in ONE request. This is done by using tcpdump to obtain the snmp packet 
   leaving the system, and comparing the detected OIDs with those that were
   included in the request. If they do not match, ERROR. 
10. Check that the prober can handle a device that is not so nice, it delays
    its the request response. Again focus on the request stability based on the
    traced packets. Target is 1s, accepted std.dev 0.1s. If not, ERROR. 
11. Check that the prober can handle a device that is not so nice, sometimes 
    it does not provide a correct response. A really bad device. Again focus 
    on the request stability based on the traced packets. Target is 1s, 
    accepted std.dev 0.1s. If not, ERROR. 


