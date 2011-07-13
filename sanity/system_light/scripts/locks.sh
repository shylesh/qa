#!/bin/bash

# GOAL : This tests try to stress fcntl locking functions. A master process set a lock on a file region (byte range locking).
# * Some slaves process tries to perform operations on this region, like read, write, set a new lock ... Expected results of this 
# * operations are known. If the operation result is the same as the expected one, the test sucess, else it fails.

function main()
{
    echo "testing the locking through concurrent processes:`date +%T`"
    time $LOCK_BIN -n $CON_PROC -f $LOCK_TEST_FILE 2>>$LOG_FILE 1>>$LOG_FILE 
    
    if [ $? -ne 0 ]; then
        echo "locks by processes failed:`date +%T`"
        err=11
    else
	echo "end:`date +%T`"
        err=0
    fi
    
    echo "DONE"
    
    echo "testing the locking through concurrent threads:`date +%T`"
    time $LOCK_BIN -n $CON_PROC -f $LOCK_TEST_FILE -T 2>>$LOG_FILE 1>>$LOG_FILE 
    
    if [ $? -ne 0 ]; then
        echo "locks by threads failed:`date +%T`"
        return 11;
    else
	echo "end threads:`date +%T`"
        if [ $err -ne 0 ]; then
            return 11;
        else
            return 0;
        fi
    fi

}

main "$@";