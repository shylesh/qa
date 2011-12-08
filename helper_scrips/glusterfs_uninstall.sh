#!/bin/bash

#set -x;

function _init ()
{
 #   echo $0;
 #   echo $#;
 #   echo $1;
    set -u;
    if [ $# -lt 1 ]; then
            echo "usage: download_and_install <glusterfs-version>";
            exit 1;
    fi

    version=$1;
    echo $version;
    echo $version | grep "glusterfs" 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
        echo "given argument is not glusterfs";
        exit 1;
    fi
}

function un_install ()
{
    cd /root/$version;

    cd build;
    make uninstall && make clean && make distclean;

    cd /root;
}

main ()
{

    if [ ! -d $version ]; then
        echo "the glusterfs version ($version) directory is not there."
        return 1;
    fi

    un_install;
}

_init "$@" && main "$@"
