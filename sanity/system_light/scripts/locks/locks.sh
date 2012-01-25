#!/bin/bash

function main()
{
    locks_dirname=$(dirname $LOCK_BIN);
    cp $locks_dirname/test $LOCK_TEST_FILE;

    $TOOLDIR/locks_run.sh;
    if [ $? -eq 0 ]; then
        rm $LOCK_TEST_FILE;
        return 0;
    else
        return 1;
    fi
}

main "$@";