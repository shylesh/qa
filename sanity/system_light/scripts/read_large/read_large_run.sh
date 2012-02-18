#!/bin/bash

function main()
{
    dd if=/dev/zero of=$PWD/$OF bs=$BS_SIZE count=$DD_CNT;

    echo "start:`date +%T`"
    time cat $LARGE_FILE_SOURCE > $LARGE_FILE_DEST 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -ne 0 ]; then
	echo "end:`date +%T`"
        return 11;
    else
	echo "end:`date +%T`"
        return 0;
    fi
}

main "$@";