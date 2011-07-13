#!/bin/sh

ulimit -c unlimited
set +x
SCRIPTS_PATH="/opt/qa/tools/system_light/scripts"
CNT=0
. /opt/qa/tools/system_light/config
echo " Changing to the specified mountpoint"
cd $THIS_TEST_DIR
pwd

echo " This script runs the tools and scriprts which are used to test the performance.The tests are run on ther glusterFS mountpoint.They are:
1.dd
2.dbench
3.arequal
4.posix_compliance
5.kernel compile
6.fsx
7.ltp tests
8.fileop
9.bonnie
10.iozone
11.openssl build
12.postmark
13.ffsb
14.Reading from large file
15.Multiple file creation(100000)
16.glusterfs build";

sleep 1

echo "Executing ffsb"
 set +x
 cp $BIN_PATH/system_light/profile_everything $THIS_TEST_DIR/profile_everything
  sed -i "s[/mnt/test1[$THIS_TEST_DIR[" profile_everything
 $SCRIPTS_PATH/ffsb_test.sh 
if [ $? -eq 0 ]; then
    CNT=$((CNT+1))
    echo $CNT
    echo "Removing data"
    rm -rfv data && echo "Removed"
    echo "Removing meta" 
    rm -rfv meta && echo "Removed"
    echo "Removing profile_everything"
    rm $FFSB_FILE && echo "Removed"
else
    echo "ffsb failed"
    echo $CNT
fi

echo "Executing ltp tests"
 set +x
 mkdir ltp
 cd  ltp
 $SCRIPTS_PATH/ltp_test.sh 
if [ $? -eq 0 ]; then
    CNT=$((CNT+1))
    echo $CNT
    echo "Removing directory"
    cd -
    rm -rfv ltp && echo "removed"
else
    echo "ltp failed"
    echo $CNT
fi

echo "Executing fileop"
 set +x
 $SCRIPTS_PATH/fileop_test.sh 
if [ $? -eq 0 ]; then
    CNT=$((CNT+1))
    echo $CNT
else
    echo "fileop failed"
    echo $CNT
fi

echo "Kernel compiling"  #Untars the given kernel file and compiles it
 set +x
 $SCRIPTS_PATH/kernel.sh 
if [ $? -eq 0 ]; then
    CNT=$((CNT+1))
    echo $CNT
    echo "Removing linux-$VERSION.tar.bz2 and linux-$VERSION"
    rm -r linux-$VERSION* && echo "removed"
else
    echo "kernel compile failed"
    echo $CNT
fi

echo "Executing bonnie++"
 set +x
 $SCRIPTS_PATH/bonnie_test.sh 
if [ $? -eq 0 ]; then
    CNT=$((CNT+1))
    echo $CNT
else
    echo "bonnie failed"
    echo $CNT
fi

