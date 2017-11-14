Test scripts for Applied Network Management class (ET2536 HT2017).
=================================================================

Introduction 
------------

These are the tests that I (Patrik Arlos) use to technically evaluate the lab 
assignments in the ET2536 class. They are written to run on my system 
(Ubuntu 16.04LTS) with 
      NET-SNMP v 5.7.3. 
      python 2.7.12
      python3 3.5.2

See installed-packages for a complete list, obtained via 
    dpkg --get-selections | grep -v deinstall > installed-packages

Please note, the tests are written to work on __MY__ system. If you want to 
use them, you need to read and understand what/how the code works. In some 
cases, you need to ADAPT the test script to fit your environment. However, when 
I eventually test your submitted solution; I'll be using my version of the 
script. 

Furthermore, the assignments have not CHANGED (and will not change). But the 
test scripts may. The scripts may change for a couple of reasons; 
	     1) the test script was not generic enough to handle/detect common 
	     	misstakes, 
	     2) the script tests the wrong thing,  
	     2) the script tests the right thing, but badly or inefficient. 

This is a normal procedure when it comes to testing a solution. 

As each test is a simple scripts. This means that the error handling is not 
complete. I.e. the test scripts do -assume- some behavior from your solutions, 
if the solution does not meet that or has a completely different behavior the 
script may miss/fail to detect this. If I note that this is a current 
behaviour, I might update the script(s) to catch this explicitly. 

For example, if the application is to give an output like this (reg.ex syntax)
\d+\s+|\s+\d+\s+|\s+...\d+\s+

\d+ : One or more integers, 
\s+ : One or more whitespaces
|   : The '|' character

I.e for a two OID case, the output should be
19214 | 1091 | 281 
19215 | 1100 | 283 

Now if the output is 
ERROR; no such OID found 19214 | | 281
ERROR; no such OID found 19214 | | 283

This is obviously NOT correct, and such a case might not be caught byt the test
scripts. If I notice that this is a common issue; I'd add an explicit test to 
catch this. 


It is a MUST/REQUIREMENT to review the output from the test scripts, despite 
that you might have gotten the 
"If you gotten this far, and there are no ERRORS or issues mentioned above, 
its probably ok." statement from the script. 



Usage
-----

Each assignment has a separate folder (A1,A2,A3,A4 and Wrapup), and a wrapper
script that tests multiple submissions (evaluateLab_*.sh). I'm the main user 
of the wrappers, as it allows me to download multiple submissions and evaluate
them at once. Hence, unless you do that you have no real interest in the 
wrapper scripts. However, they use the test scripts. So if you like to see 
how I call the test scripts you can take a peek into them.

In each folder you find a test script,
   A1:   checkA1.sh
   A2:   checkA2.sh
   A3:   checkA3.sh
   A4:   checkA4.sh
   Wrapup:   checkMe.sh

They are called like 
     ./check*.sh <folder containing your solution, A1--A4)

With the exception of Wrapup, that is called
     ./checkWrapup.sh <archive>

please recall that the archive name needs to be et2536-<acro>.tar.gz, where
<acro> is your student acronym. 


For details about the individual tests/scripts see the readme.md in the 
corresponding folder. 


Example(s)
-------

To test A1, run  (within the A1 directory)
./checkA1.sh ~/myA1

To test A2, run  (within the A2 directory)
./checkA2.sh ~/myA2

To test A3, run  (within the A3 directory)
./checkA3.sh ~/myA3

To test A4, run  (within the A4 directory)
./checkA4.sh ~/myA4

To test Wrapup, run  (within the Wrapup directory)
./checkWrapup.sh et2536-pal.tar.gz





 



