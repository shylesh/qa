#!/bin/bash

function main ()
{
    $TOOLDIR/arequal_run.sh;

    if [ $? -eq 0 ]; then
        rm -r $ARE_DST && echo "removed";
        return 0;
    else
        return 1;
    fi
}

main "$@"
