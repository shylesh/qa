#!/bin/bash

function main()
{

    echo "start:`date +%T`"
    time fileop -f $FILEOP_CNT -t  2>>$LOG_FILE 1>>$LOG_FILE


#in this example it creates 2 directories.In each directory 2 subdirectories are created and in each subdirectory 2 files are created.

    if [ $? -ne 0 ]; then
        echo "end:`date +%T`"
        return 11;
    else
        echo "end:`date +%T`"
        return 0;
    fi

}

main "$@";