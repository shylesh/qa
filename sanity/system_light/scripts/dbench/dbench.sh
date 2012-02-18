#!/bin/bash

function main()
{
    $TOOLDIR/dbench_run.sh;
    if [ $? -eq 0 ]; then
        rm -r clients && echo "removed clients";
        return 0;
    else
        return 1;
    fi
}

main "$@";