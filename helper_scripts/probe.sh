#!/bin/bash

function _init ()
{
    set -u;
}

function peer_probe ()
{
    local remote_server=;

    if [ $# -eq 1 ]; then
	remote_server=$1;
    fi

    if [ $remote_server ]; then
	gluster peer probe $remote_server;
	return 0;
    fi

    for i in $(cat /root/servers)
    do
      peer_probe $i;
    done

}

function main ()
{
    stat --printf=%i /root/servers 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
	echo "servers file is not present /root. Cannot execute further."
	exit 1
    fi

    peer_probe;

    return 0;
}

_init && main "$@"
