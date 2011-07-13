#!/bin/bash

function main ()
{
    echo "start:`date +%T`" 
    time ffsb $FFSB_FILE 2>>$LOG_FILE 1>>$LOG_FILE


    if [ $? -ne 0 ]; then
	echo "end:`date +%T`" >>$LOG_FILE
	return 11;
    else
	echo "end:`date +%T`" >>$LOG_FILE
	return 0;
    fi
    
}

main "$@";