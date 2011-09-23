#!/bin/bash

function _init ()
{
    #GIT_DIR="/opt/users/nightly_sanity/glusterfs.git"
    GIT_DIR="/root/sanity/glusterfs.git";
    GIT_FILE="/tmp/git_head_`date +%F`";
    rm /tmp/git_head*;
    export PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/qa/tools

    if [ ! -e /root/branch ]; then
        touch /root/branch;
    fi

    cd $GIT_DIR;
    branch=$(cat /root/branch);
    echo $branch;
    if [ "$branch" != "master" ]; then
        checkout_branch;
        if [ $? -ne 0 ]; then
            branch="master";
            git checkout $branch;
        fi
    else
        branch="master";
        git checkout $branch;
    fi
    cd -;
}

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

    echo "========PATCHES========";

    for i in $(ls /root/patches)
    do
      $GIT_PATH apply /root/patches/$i;
      echo $i >> $GIT_FILE
    done

    #$GIT_PATH diff >> $GIT_FILE;

    cp -r /root/patches/ /tmp/;
    rm -f /root/patches/*;
}

function checkout_branch ()
{
    local ret=0;
    git branch | grep $branch;
    if [ $? -ne 0 ]; then
        git checkout -b $branch origin/$branch;
        if [ $? -ne 0 ]; then
            ret=22;
        fi
    fi

    if [ $ret -eq 0 ]; then
        git checkout $branch;
        if [ $? -ne 0 ]; then
            ret=22;
        fi
    fi

    return $ret;
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
    dist_repl_sanity;
    dist_stripe_sanity;
    return 0;
}

_init "$@" && main "$@"