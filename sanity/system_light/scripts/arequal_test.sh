#!/bin/bash

function main ()
{
    stat $ARE_SRC | grep directory > /dev/null
    if [ $? -eq 0 ] ; then
	ARE_SRC=$ARE_SRC/
    fi
 
    echo "start:`date +%T`" 
    time arequal-run.sh $ARE_SRC $ARE_DST  2>>$LOG_FILE 1>>$LOG_FILE 
 #copies the contents of $4 directory to $5 and calculates the checksum of both src and dst directories to check whether the transfer was successful. We need to redirect the standard output also to the logfile to see the output of arequal.


    if [ $? -ne 0 ]; then
	echo "end:`date +%T`"
	return 11;
    else
	echo "end:`date +%T`" 
    fi
}

main "$@"