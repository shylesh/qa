#!/bin/bash

function main ()
{
    echo "start:`date +%T`" 
    time dd if=/dev/zero of=$PWD/$OF bs=$BS_SIZE count=$DD_CNT 2>>$LOG_FILE #copies specified amount of data from the input file to the output file


    if [ $? -ne 0 ]; then
	echo "end:`date +%T`" 
	return 11;
    else
	echo "end:`date +%T`" 
	return 0;
    fi

}

main "$@";