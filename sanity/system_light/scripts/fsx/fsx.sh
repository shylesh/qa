#!/bin/bash

function main ()
{
    $TOOLDIR/fsx_run.sh;
    if [ $? -eq 0 ]; then
        rm $FSX_FILE* && echo "Removed fsx file"
        return 0;
    else
        return 1;
}

main "$@";