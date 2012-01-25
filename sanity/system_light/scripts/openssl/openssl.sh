#!/bin/bash

function main()
{
    $TOOLDIR/openssl_run.sh;
    if [ $? -eq 0 ]; then
        rm -rf openssl* && echo "removed openssl directories and files";
        return 0;
    else
        return 1;
    fi
}

main "$@";
