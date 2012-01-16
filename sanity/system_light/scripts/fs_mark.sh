#!/bin/bash

function main ()
{

    echo "start: `date +%T`"

    for i in `seq 1 6`
    do
        time fs_mark -d . -D SUBDIR_COUNT -t THR_COUNT -S $i 2>>$LOG_FILE 1>>$LOG_FILE
        if [ $? -ne 0 ]; then
            echo "end:`date +%T`";
            return 11;
        fi
    done

    echo "end:`date +%T`";
    return 0;
}

main "$@";
