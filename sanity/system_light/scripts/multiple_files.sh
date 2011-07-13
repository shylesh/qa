#!/bin/bash

# This script creates a directory,creates large number of files in it, lists the contnts of the directory and removes the files

function main ()
{
    mkdir test
    cd test
    
    echo "start:`date +%T`"
    for i in `seq 1 $NUM_OF_FILES` ; do
        dd if=/dev/zero of=file$i bs=10K count=1 1>/dev/null 2>/dev/null
    done 
    echo "end:`date +%T`"

    echo "Creation of $NUM_OF_FILES done"
    
    TOTAL_FILES=$(ls | wc -l) 

    if [ $TOTAL_FILES -ne $NUM_OF_FILES ]; then
        echo "Total files created is not $NUM_OF_FILES"
        err=11
    else
        err=0
    fi
    
    echo "Removing all the files"
    
    for i in `seq 1 $NUM_OF_FILES` ; do
        rm file$i
    done

    cd ..
    rmdir test
    if [ $err -ne 0 ]; then
        return $err
    else
        return 0;
    fi
}


main "$@";
