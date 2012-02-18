#! /bin/bash

function main ()
{
    echo "start: `date +%T`";
    time prove -r $DIR/tests "$@" | tee -a /tmp/posix 2>/dev/null 1>/dev/null;
    cat /tmp/posix && sleep 2;
    grep FAILED /tmp/posix  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -ne 0 ]; then
        echo "end: `date +%T`";
        return 0;
    else
        echo "end: `date +%T`";
        return 1;
    fi
}

main "$@"