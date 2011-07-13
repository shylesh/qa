#!/bin/bash

function main()
{
#runs $3 multiple clients on mount point and tests the performance and -t option ($2) tells the time for which it should be run  
    echo "start:`date +%T`"
    time dbench -t $TIME -s -S $DBENCH_CLNTS 2>>$LOG_FILE 1>>$LOG_FILE


    if [ $? -ne 0 ]; then
	echo "end:`date +%T`"
        return 11;
    else
	echo "end:`date +%T`"
        return 0;
    fi
    
}

main "$@";