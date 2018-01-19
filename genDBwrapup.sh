#!/bin/bash

userid=$1

echo "$host=\"10.10.0.15\"; "  > db.conf
echo "$port=\"3306\"; " >> db.conf
echo "$database= \"et2439t7-$userid\"; " >> db.conf 
echo "$username=\"et2536t7\"; " >> db.conf
echo "$password=\"konko\"; " >> db.conf



mysql -u root -h 10.10.0.15 -p atslabb < sed -i /USERIDTAG/$userid/ig wrapup-db.sql

To Student:
Thanks,  you can login to <IP> use ubuntu as username, and your key for authentication. 
In the home folder you find your submission archive, and a db.conf file to use. Furthermore, the system has apache or nginx installed, and its serving from /var/www/html. As your user has sudo rights, you can become root and install/configure what ever you need. However, make sure that you dont break the network connectivity. 

Make sure that your solution works, as some of your solutions require to collect some data please start the collection processes as soon as possible. 

As the device is behind NAT, the local ip may be confusing. However; you can access the device via SSH and http (port 80). 

I will send an calender invite, and during that demo we will check all four assignments, and discuss your solution. We will both be logged in to the device, and we will use screen so I can see what you type. Hence, when you login set up 3 different ssh connections, and attach each to a different screen (use screen -x z<session name> (http://technonstop.com/screen-commands-for-terminal-sharing). I'll provide the session names. At the same time we will have a skype/hangout video session going, so I can see and hear you. If you have any questions, please let me know (via email)
