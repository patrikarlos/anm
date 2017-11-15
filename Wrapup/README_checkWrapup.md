checkWrapup.sh
==============

Introduction
------------

Checks an archive submission, this is a wrapper script intended to test a single archive. 

Usage
-----

./checkWrapup.sh <archivename>

Test Sequence
-------------
1. Check that the archivename is et2536-<acro>.tar.gz, if not ERROR.

2. Unpack archive to an temporary folder (/tmp/ANM-XXXX). This should result
   in a folder et2536-<acro> being created and an unpack.log creatd in that
   folder. If additional files/folders are found, ERROR.

Copy reference db.conf to the folder /tmp/ANM-XXX/et2536-<acro>. 
Call 
     checkMe.sh <classid-userid> /tmp/ANM-XXX/et2536-<acro>/myLog 2 

This will use the same testing as the evaluateLabs_Wrapup.sh (checkMe.sh), it 
needs the classid-userid (folder in archive), where to log output (in 
same folder as the unpack.log, not user folder) and log mode 2, both STDOUT
and FILE (myLog).

See README_checkMe.md for details on it. 

Once it returns check if Missing or Error are present. Of course, you need to watch
the output as the script runs. 