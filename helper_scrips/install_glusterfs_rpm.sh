#!/bin/bash

function _init ()
{
    set -u;
    VERSION=$1;
    if [ $# -lt 2 ]; then
	upgrade="no";
    else
	if [ $2 == "yes" ]; then
	    upgrade="yes";
	else
	    upgrade="no";
	fi
    fi
}

function install_glusterfs ()
{
    local remote_server=;

    if [ $# -eq 1 ]; then
	remote_server=$1;
    fi

    if [ $remote_server ]; then
	ssh $remote_server cp -f /root/scripts/rpm_download_install.sh /root/;
	ssh $remote_server /root/rpm_download_install.sh $VERSION $upgrade;
	return 0;
    fi

    j=0;
    for i in $(cat /root/machines)
    do
      j=$(($j+1));
      (install_glusterfs $i)&
    done

}

function install_my_glusterfs ()
{
    old_PWD=$PWD;

    cd /root;
    cp /root/scripts/rpm_download_install.sh /root/;
    /root/rpm_download_install.sh $VERSION $upgrade;

    cd $old_PWD;
    return 0;
}

function main ()
{
    stat --printf=%i /root/machines 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
	echo "servers file is not present /root. Cannot execute further.";

	exit 1;
    fi

    install_glusterfs;
    for i in $(1 $j)
    do
      wait %$j;
    done

    install_my_glusterfs;

    return 0;
}

_init "$@" && main "$@"
    

