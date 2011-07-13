#!/bin/bash

#This program runs the tool postmark which is a filesystem benchmark program. To know the details of it see the man page.
function main()
{

    echo "start:`date +%T`"
    time postmark $POST_FILE 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -ne 0 ]; then
	echo "end:`date +%T`"
        return 11;
    else
	echo "end:`date +%T`"
        return 0;
    fi
}

main "$@";