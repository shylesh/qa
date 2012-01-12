#!/bin/bash


function _init ()
{
    set -u;
    volume_name=$1;
}

function start_and_stop ()
{
    while true;
    do
      gluster --mode=script volume stop $volume_name;
      sleep 1;
      gluster volume start $volume_name;
      sleep 1;
    done

    return 0;
}

function main ()
{

    start_and_stop;

    return 0;
}

_init "$@" && main "$@"