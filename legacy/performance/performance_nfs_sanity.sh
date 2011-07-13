#!/bin/bash

#GIT_DIR="/opt/users/nfs_performance/glusterfs.git"
GIT_DIR="/root/sanity/glusterfs.git"
GIT_FILE="/tmp/git_head_`date +%F`"

rm /tmp/git_head*

function update_git ()
{

    cd $GIT_DIR
    echo $PWD >> $GIT_FILE
    echo "preveious head is at:"
    /usr/bin/git show >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git show failed. Exiting"
	return 11;
    fi

    echo "Doing git reset:"
    /usr/bin/git reset --hard >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git reset failed. Exiting."
	return 11;
    fi

    echo "Doing git pull:"
    /usr/bin/git pull >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git pull failed"
	return 11;
    else
	echo "git pull succeeded"
    fi
    
    echo "Current head is at:"
    /usr/bin/git show >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git show failed, but continuing"
	return 0;
    else
	return 0;
    fi
}
    
function dht_sanity ()
{
    echo "DHT testing"
    sleep 1
    /opt/users/nightly_performance/nightly_performance.sh -t dht -c 1 -m fuse 2>&1 | tee /mnt/runlog.dht
    echo "DHT done"
    sleep 1
    return 0;
}

function afr_sanity ()
{
    echo "AFR testing"
    sleep 1
    /opt/users/nightly_performance/nightly_performance.sh -t afr -c 1 -m fuse 2>&1 | tee /mnt/runlog.afr
    echo "AFR done"
    sleep 1
}

function stripe_sanity ()
{
    echo "stripe testing"
    sleep 1
    /opt/users/nightly_performance/nightly_performance.sh -t stripe -c 1 -m fuse 2>&1 | tee /mnt/runlog.stripe
    echo "stripe done"
    sleep 1
}

function main ()
{

    update_git;
    dht_sanity;
    afr_sanity;
    stripe_sanity;
    return 0;
}

main "$@"