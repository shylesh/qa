#!/bin/bash

#This script 1st searches in the pwd for the kernel tar file. If its not there then based on the value of the vriable KERNEL_PATH it either searches from the path given or searches in http://www.kernel.org

function main()
{
    SCRIPTS_DIR=$(dirname $0);
    if [ -e "linux-$VERSION.tar.bz2" ]
    then
	echo "start:`date +%T`"
        time $SCRIPTS_DIR/kernel_compile.sh linux-$VERSION.tar.bz2 2>>$LOG_FILE 1>>$LOG_FILE 
        if [ $? -ne 0 ]; then
            err=$?
	    echo "end:`date +%T`"
            return 11;
        else
	    echo "end:`date +%T`"
            return 0;
        fi
    elif [ -z "$KERNEL_PATH" ]
    then
        time $SCRIPTS_DIR/kernel_compile.sh  2>>$LOG_FILE 1>>$LOG_FILE 
        if [ $? -ne 0 ]; then
            err=$?
	    echo "end:`date +%T`"
            return 11;
        else
	    echo "end:`date +%T`"
            return 0;
        fi
    else
        time $SCRIPTS_DIR/kernel_compile.sh $KERNEL_PATH  2>>$LOG_FILE 1>>$LOG_FILE 
        if [ $? -ne 0 ]; then
            err=$?
	    echo "end:`date +%T`"
            return 11;
        else
	    echo "end:`date +%T`"
            return 0;
        fi
    fi;
}

main "$@";