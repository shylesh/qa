#!/bin/bash

function main ()
{

    ### test this part later #####
    #old_PWD=$PWD;
    ### test the above part later #####

    mkdir ltp;
    cd  ltp;

    $TOOLDIR/ltp_run.sh;
    if [ $? -eq 0 ]; then
         rm -rfv ltp && echo "removed ltp directories";
         return 0;
    else
        return 1;
    fi

}

main "$@"