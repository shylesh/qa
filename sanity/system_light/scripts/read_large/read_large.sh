#!/bin/bash

function main ()
{
    $TOOLDIR/read_large_run.sh;

    if [ $? -eq 0 ]; then
        rm $PWD/$OF && echo "Removed large file";
        return 0;
    else
        return 1;
    fi
}

main "$@"