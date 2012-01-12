#!/bin/bash

#set -x;

function _init ()
{
 #   echo $0;
 #   echo $#;
 #   echo $1;
    set -u;
    if [ $# -lt 1 ]; then
	    echo "usage: download_and_install <glusterfs-version> [upgrade decision]";
	    exit 1;
    fi

    version=$1;
    echo $version;
    echo $version | grep "glusterfs" 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
	echo "given argument is not glusterfs";
	exit 1;
    fi

    version_number=$(echo $version | cut -f 2 -d "-");
    check_if_qa_release $version;
    op_ret=$?;

    if [ $op_ret -eq 0 ]; then
	download_address="http://bits.gluster.com/pub/gluster/glusterfs/";
    fi

    echo "KK: $download_address"
# 	ls -l "$version".tar.gz 2>/dev/null 1>/dev/null
# 	if [ $? -ne 0 ]; then
}

function check_if_qa_release ()
{
    glusterfs_version=$1;

    echo $glusterfs_version | grep "qa" 2>/dev/null 1>/dev/null;
    ret=$?;

    return $ret;
}

function download_rpms ()
{
    address=$1;

    mkdir $PWD/rpms/$version_number;

    cd $PWD/rpms/$version_number;

    echo version_number | grep "3.2";
    is_32=$?;

    wget $address/$version_number/x86_64/glusterfs-core-$version_number-1.x86_64.rpm;
    wget $address/$version_number/x86_64/glusterfs-debuginfo-$version_number-1.x86_64.rpm;
    wget $address/$version_number/x86_64/glusterfs-fuse-$version_number-1.x86_64.rpm;
    if [ $is_32 -eq 0 ]; then
	wget $address/$version_number/x86_64/glusterfs-geo-replication-$version_number-1.x86_64.rpm;
    fi
}


function install_or_upgrade ()
{
    cd /root/rpms/$version_number;
    if [ $upgrade != "yes" ]; then
	for i in $(ls)
	do
	  rpm -ivh $i;
	done
    else
	for i in $(ls)
	do
	  rpm -Uvh $i;
	done
    fi

    ret=$?;
    cd /root;

    return $ret;
}

main ()
{
    echo $download_address;
    download_rpms $download_address;

    upgrade="no";
    if [ $# -eq 2 ]; then
	    upgrade=$2;
    fi

    if [ $upgrade != "yes" ] && [ $upgrade != "no" ]; then
	echo "Invalid upgrade decision $upgrade";
	rm -rf /root/rpms/$version_number;
	exit 1;
    fi

    install_or_upgrade $upgrade;
    ret=$?;
    if [ $ret -ne 0 ]; then
	rm -rf /root/rpms/$version_number;
    fi
}

_init "$@" && main "$@"
