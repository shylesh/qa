#!/bin/bash

function main ()
{
    $TOOLDIR/dd_run.sh;
    if [ $? -eq 0 ]; then
        rm -f $PWD/$OF && echo "dd file removed";
        return 0;
    else
        return 1;
    fi
}

main "$@"