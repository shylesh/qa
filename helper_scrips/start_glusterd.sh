#!/bin/bash

function _init ()
{
    set -u;
}

function start_glusterd ()
{
    local remote_server=;

    if [ $# -eq 1 ]; then
        remote_server=$1;
    fi

    if [ $remote_server ]; then
        ssh $remote_server glusterd;
        return 0;
    fi

    for i in $(cat /root/servers)
    do
      start_glusterd $i;
    done

}

function start_my_glusterd ()
{
    glusterd;
    return $?;
}

function main ()
{
    stat --printf=%i /root/servers 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
        echo "servers file is not present /root. Cannot execute further."
        exit 1
    fi

    start_glusterd;
    start_my_glusterd;

    return 0;
}

_init && main "$@"
