#!/bin/bash

# This script takes glusterfs tar file, untars it and builds it.

function main ()
{

    echo "cloning from the git:`date +%T`" >>$LOG_FILE
    time git clone git://git.gluster.com/glusterfs.git glusterfs.git 2>>$LOG_FILE 1>>$LOG_FILE
    if [ $? -ne 0 ]; then
        echo "Cannot clone the git repository"
        tar -xvf $GLUSTERFS_TAR_FILE
        mv glusterfs-$GFS_VERSION glusterfs.git
    fi

    cd $GLUSTERFS_DIR

    echo "running autogen.sh:`date +%T`"
    time ./autogen.sh 2>>$LOG_FILE 1>>$LOG_FILE 

    if [ $? -ne 0 ]; then
        echo "autogen failed:`date +%T`";
        return 11;
    fi

    echo "running configure:`date +%T`"
    time ./configure 2>>$LOG_FILE 1>>$LOG_FILE 

    if [ $? -ne 0 ]; then
        echo "configure failed:`date +%T`";
        return 11;
    fi
    

    echo "running make:`date +%T`"
    time make -j 32 2>>$LOG_FILE 1>>$LOG_FILE 

    if [ $? -ne 0 ]; then
        echo "make failed:`date +%T`";
	return 11;
    else
	echo "all successful:`date +%T`"
        return 0;
    fi

}

main "$@"