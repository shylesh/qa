#!/bin/bash

function main ()
{
    $TOOLDIR/kernel.sh;

    if [ $? -eq 0 ]; then
        rm -r linux-$VERSION* && echo "removed kernel";
        return 0;
    else
        return 1;
    fi
}

main "$@"