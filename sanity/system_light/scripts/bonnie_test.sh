#!/bin/bash

function main()
{
    echo "start:`date +%T`" >>$LOG_FILE
    time bonnie++ -u $USER_NAME -d $WD 2>&1 1>>$LOG_FILE 1>>/tmp/bonnie  #creates files of double the ram size and tests the performance


    if [ $? -ne 0 ]; then
	echo "end:`date +%T`" >>$LOG_FILE
	return 11;
    else
	echo "end:`date +%T`" >>$LOG_FILE
	return 0;
    fi
}

main "$@"
