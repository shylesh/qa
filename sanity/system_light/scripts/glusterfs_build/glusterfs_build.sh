#!/bin/bash

function main ()
{
    $TOOLDIR/build_glusterfs.sh;
    if [ $? -eq 0 ]; then
        rm -r $GLUSTERFS_DIR && echo "glusterfs directory removed";
        return 0;
    else
        return 1;
    fi
}

main "$@"