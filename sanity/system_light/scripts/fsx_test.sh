#!/bin/bash

#performs read,write operations on the given file and tests the performance

function main ()
{
    cp $FSX_FILE_ORIG $FSX_FILE

    echo "start:`date +%T`" 
    time fsx -R -W -N $NUM_OPS $FSX_FILE 2>>$LOG_FILE 1>>$LOG_FILE
    
    if [ $? -ne 0 ]; then	
	echo "end:`date +%T`" 
        return 11;
    else
	echo "end:`date +%T`" 
        return 0;
    fi
}

main "$@";