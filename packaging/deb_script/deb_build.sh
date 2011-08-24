#!/bin/bash
set -x
VERSION=$1
BUILD_ROOT=`pwd`

function download_src(){
#download the package
wget http://bits.gluster.com//pub/gluster/glusterfs/src/glusterfs-$VERSION.tar.gz
}

function make_orig()
{
#cp as orig.
cp glusterfs-$VERSION.tar.gz glusterfs-$VERSION.orig.tar.gz
cp glusterfs-$VERSION.tar.gz glusterfs_$VERSION.orig.tar.gz
}

function file_untar()
{
#untar 
tar -zxvf glusterfs-$VERSION.tar.gz
}

function create_debian_dir()
{
cd glusterfs-$VERSION
#dh_make
dh_make<<EOF
s

EOF
}


function rmfiles_debian_dir(){
#remove files
rm -rf $BUILD_ROOT/glusterfs-$VERSION/debian/copyright docs README.* *.?x
rm -rf $BUILD_ROOT/glusterfs-$VERSION/debian/docs
rm -rf $BUILD_ROOT/glusterfs-$VERSION/debian/README.*
rm -rf $BUILD_ROOT/glusterfs-$VERSION/debian/*.?x
rm -rf $BUILD_ROOT/glusterfs-$VERSION/debian/glusterfs*
}


function edfiles_debian_dir(){
cd $BUILD_ROOT
#modify
sed -i "s/3.2.3/$VERSION/g" $BUILD_ROOT/glusterfs-$VERSION/debian/changelog

#cp control
cp $BUILD_ROOT/files/control $BUILD_ROOT/glusterfs-$VERSION/debian

#cp postinst
cp $BUILD_ROOT/files/postinst $BUILD_ROOT/glusterfs-$VERSION/debian

#cp rules
cp $BUILD_ROOT/files/rules $BUILD_ROOT/glusterfs-$VERSION/debian
}

function start_debbuild(){
#move 
cd $BUILD_ROOT/glusterfs-$VERSION
apt-get -y remove libibverbs-dev libibverbs1
#start the build
DEB_BUILD_OPTIONS=noopt,nostrip debuild
}



function start_debbuild_with_rdma(){
#move 
cd $BUILD_ROOT/glusterfs-$VERSION
apt-get -y install libibverbs-dev libibverbs1

#cp control
cp $BUILD_ROOT/files/control_ib $BUILD_ROOT/glusterfs-$VERSION/debian/control

#start the build
DEB_BUILD_OPTIONS=noopt,nostrip debuild
}

function mv_files(){
mkdir  $BUILD_ROOT/glfs-$VERSION
mv $BUILD_ROOT/glusterfs_$VERSION-1_amd64.deb $BUILD_ROOT/glfs-$VERSION
}

function mv_ib_files(){
mkdir  $BUILD_ROOT/glfs-$VERSION -p
cp $BUILD_ROOT/glusterfs_$VERSION-1_amd64.deb $BUILD_ROOT/glfs-$VERSION/glusterfs_$VERSION-1_with_rdma_amd64.deb 
}

############Main part################

download_src
make_orig
file_untar
create_debian_dir
rmfiles_debian_dir
edfiles_debian_dir
start_debbuild
mv_files
start_debbuild_with_rdma
mv_ib_files
#####################
