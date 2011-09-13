#!/bin/bash

#set -x;

function _init ()
{
 #   echo $0;
 #   echo $#;
 #   echo $1;
    set -u;
    if [ $# -lt 1 ]; then
            echo "usage: download_and_install <glusterfs-version> [install prefix]";
            exit 1;
    fi

    version=$1;
    echo $version;
    echo $version | grep "glusterfs" 2>/dev/null 1>/dev/null;
    if [ $? -ne 0 ]; then
        echo "given argument is not glusterfs";
        exit 1;
    fi

    check_if_qa_release $version;
    op_ret=$?;

    if [ $op_ret -eq 0 ]; then
        download_address="http://bits.gluster.com/pub/gluster/glusterfs/src/"$version".tar.gz";
    else
        echo $version | grep "3.2" 2>/dev/null 1>/dev/null;
        if [ $? -eq 0 ]; then
            version_number=$(echo $version | cut -f 2 -d "-");
            download_address="http://ftp.gluster.com/pub/gluster/glusterfs/3.2/$version_number/"$version".tar.gz";
        else
            grep "3.1" $version 2>/dev/null 1>/dev/null;
            echo "haha yes"
            if [ $? -eq 0 ]; then
                version_number=$(echo $version | cut -f 2 -d "-");
                download_address="http://ftp.gluster.com/pub/gluster/glusterfs/3.1/$version_number/"$version".tar.gz";
            else
                grep "3.0" $version 2>/dev/null 1>/dev/null;
                if [ $? -eq 0 ]; then
                    version_number=$(cut -f 2 -d "-" $version);
                    download_address="http://ftp.gluster.com/pub/gluster/glusterfs/3.2/$version_number/"$version".tar.gz";
                fi
            fi
        fi
    fi

echo "KK: $download_address"
#       ls -l "$version".tar.gz 2>/dev/null 1>/dev/null
#       if [ $? -ne 0 ]; then
}

function check_if_qa_release ()
{
    glusterfs_version=$1;

    echo $glusterfs_version | grep "qa" 2>/dev/null 1>/dev/null;
    ret=$?;

    return $ret;
}

function download_tarball ()
{
    address=$1;

    wget $address;
}

function untar_tarball ()
{
    gluster_version=$1;

    tar xzf $PWD/"$gluster_version".tar.gz;
}

function configure ()
{
    if [ $# -eq 1 ]; then
            prefix_dir=$1;
    else
        prefix_dir="default";
    fi

    old_pwd=$PWD;

    cd $PWD/$version;
    check_if_qa_release $version;

    if [ $? -eq 0 ]; then
        export CFLAGS="-g -O0 -DDEBUG";
    else
        export CFLAGS="-g -O0";
    fi

    if [ ! -d build ]; then
        mkdir build;
    fi

    cd build;

    echo "KKKKK: $prefix_dir"
    sleep 1;
    if [ $prefix_dir != "default" ]; then
        ../configure --prefix=$prefix_dir --quiet;
    else
        ../configure --quiet;
    fi

    cd $old_pwd;
}

function build_install ()
{
    cd $PWD/$version;

    cd build;
    make -j 32 >/dev/null && make -j 32 install >/dev/null;

    cd /root;
}

main ()
{
    if [ ! -e $version.tar.gz ]; then
        echo $download_address;
        download_tarball $download_address;
    else
        echo "tarball already present in the directory";
    fi

    if [ ! -d $version ]; then
        untar_tarball $version;
    else
        echo "Source directory already present in the directory";
    fi

    install_prefix="default";
    if [ $# -eq 2 ]; then
            install_prefix=$2;
    fi

    if [ $install_prefix != "default" ]; then
        configure $install_prefix;
    else
        configure;
    fi

    build_install;
}

_init "$@" && main "$@"
