#!/bin/bash

function main ()
{
    $TOOLDIR/posix_compliance_run.sh;
    if [ $? -eq 0 ]; then
        rm -rf fstest_* && echo "removed posix compliance directories";
        return 0;
    else
        return 1;
    fi
}

main "$@"