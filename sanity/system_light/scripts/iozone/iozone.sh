#!/bin/bash


#tests the performance by performing actions such as read, write etc.

function main()
{
    echo "start:`date +%T`"
    #time iozone -i 0 -i 1 -i 2 -i 3 -i 4 -i 5 -i 6 -i 7 -i 8 -i 9 -i 10 -i 11 -i 12 -s $FILE_SIZE -r $RECORD_SIZE 2>&1 1>>$LOG_FILE 1>>/tmp/iozone
        #time iozone -i 0 -i 1 -i 2 -i 3 -i 4 -i 5 -i 6 -i 7 -i 8 -i 9 -i 10 -i 11 -i 12 -s 1m -r 22k 2>&1 1>>$LOG_FILE 1>>/tmp/iozone
    time iozone -a 2>&1 1>>$LOG_FILE 1>>/tmp/iozone
    if [ $? -ne 0 ]; then
	echo "end:`date +%T`"
        return 11;
    else
	echo "end:`date +%T`"
        return 0;
    fi
}

main "$@";