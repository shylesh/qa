#!/bin/bash

#GIT_DIR="/opt/users/nightly_sanity/glusterfs.git"
GIT_DIR="/root/sanity/glusterfs.git"
GIT_FILE="/tmp/git_head_`date +%F`"

rm /tmp/git_head*

function update_git ()
{

    GIT_PATH=$(which git);
    cd $GIT_DIR
    echo $PWD >> $GIT_FILE
    sleep 2;
    echo "preveious head is at:"
    $GIT_PATH describe >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git describe failed. Exiting"
	return 11;
    fi

    echo "Doing git reset:"
    $GIT_PATH reset --hard >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git reset failed. Exiting."
	return 11;
    fi

    echo "Doing git pull:"
    $GIT_PATH pull >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git pull failed"
	return 11;
    else
	echo "git pull succeeded"
    fi
    
    echo "Current head is at:"
    $GIT_PATH describe >> $GIT_FILE
    if [ $? -ne 0 ]; then
	echo "git describe failed, but continuing"
	#return 0;
        #else
	#return 0;
    fi

    for i in $(ls /root/patches)
    do
      $GIT_PATH apply /root/patches/$i;
    done

    echo "========DIFF========";
    $GIT_PATH diff >> $GIT_FILE;    

    rm -f /root/patches/*;
}
    
function dht_sanity ()
{
    echo "DHT testing"
    sleep 1
    /opt/users/nightly_sanity/nightly_updated.sh -t dht -c 1 -m fuse 2>&1 | tee /mnt/runlog.dht
    echo "DHT done"
    sleep 1
    return 0;
}

function afr_sanity ()
{
    echo "AFR testing"
    sleep 1
    /opt/users/nightly_sanity/nightly_updated.sh -t afr -c 1 -m fuse 2>&1 | tee /mnt/runlog.afr
    echo "AFR done"
    sleep 1
}

function stripe_sanity ()
{
    echo "stripe testing"
    sleep 1
    /opt/users/nightly_sanity/nightly_updated.sh -t stripe -c 1 -m fuse 2>&1 | tee /mnt/runlog.stripe
    echo "stripe done"
    sleep 1
}

function dist_repl_sanity ()
{
    echo "distributes replicate testing";
    sleep 1;
    /opt/users/nightly_sanity/nightly_updated.sh -t disrep -c 1 -m fuse 2>&1 | tee /mnt/runlog.dist_repl
    echo "distributed replicate done"
    sleep 1
}

function dist_stripe_sanity ()
{
    echo "distributes stripe testing";
    sleep 1;
    /opt/users/nightly_sanity/nightly_updated.sh -t dis-stripe -c 1 -m fuse 2>&1 | tee /mnt/runlog.dist_stripe
    echo "distributed stripe done"
    sleep 1
}

function main ()
{

    update_git;
    dht_sanity;
    afr_sanity;
    stripe_sanity;
#    dist_repl_sanity;
#    dist_stripe_sanity;
    return 0;
}

main "$@"