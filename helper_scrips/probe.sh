#!/bin/bash

function _init ()
{
    set -u;
}

function clean_logs ()
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
      clean_logs $i;
    done

}

function main ()
{
    stat --printf=%i /root/servers 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
	echo "servers file is not present /root. Cannot execute further."
	exit 1
    fi

    clean_logs;

    return 0;
}

_init && main "$@"
    

