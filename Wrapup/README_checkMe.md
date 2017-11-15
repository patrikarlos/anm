checkMe.sh
==============

Introduction
------------

Checks an archive submission. However, it ONLY checks that the right files are 
submitted. No actual TESTING is done (may change). 


Usage
-----

#expects to be in the build folder
~/<appropriatepath>/checkMe.sh <classid-userid> <log file> <logtype>




Test Sequence
-------------
1. Check that readme.txt exists, if not missing.  

2. Check that the db.conf provided by the user has the correct information port, 
database, username and password are present. If not missing. 

3. Foreach assignment check that a readme.txt is present, if not missing. 

4. If not all assignments submitted, ERROR.
   Requires folder to be present and readme.txt too.

Look into assignment1

5. Check that assignment1/readme.txt exist, if not Missing.
6. Check that assignment1/mrtgconf exist, if not Missing.
7. Check that assignment1/mrtgconf has the exec bit set, if not Missing.
8. Check that assignment1/backend exist, if not Missing.
9. Check that assignment1/backend has the exec bit set, if not Missing.
10. Check that assignment1/backend.sh exist, if not Missing.
11. Check that assignment1/backend.sh has the exec bit set, if not Missing.
12. Check that assignment1/index.* exist, if not Missing.
13. Check if assignment1/Makefile exist, if not no problem its optional. 

Look into assignment2

14. Check that assignment2/readme.txt exist, if not Missing.
15. Check if assignment2/Makefile exist, if not no problem its optional. 
16. Check that assignment1/backend exist, if not Missing.
17. Check that assignment1/backend has the exec bit set, if not Missing.
18. Check that assignment1/backend.sh exist, if not Missing.
19. Check that assignment1/backend.sh has the exec bit set, if not Missing.
20. Check that assignment1/index.* exist, if not Missing.

Look into assignment3
21. Check that assignment3/readme.txt exist, if not Missing.
22. Check if assignment3/Makefile exist, if not no problem its optional. 
23. Check that assignment3/trapDeamon exist, if not Missing.
24. Check that assignment3/snmptrapd.conf exist, if not Missing.
25. Check that assignment3/index.* exist, if not Missing.


