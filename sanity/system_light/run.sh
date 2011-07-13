#!/bin/sh

_init ()
{
    ulimit -c unlimited
    set +x
    set -u;
    basedir=$(dirname $0);
    SCRIPTS_PATH=$basedir/scripts;
    #SCRIPTS_PATH="/opt/qa/tools/system_light/scripts"
    CNT=0
    . $basedir/config;
    #. /opt/qa/tools/system_light/config

    echo " This script runs the tools and scriprts which are used to test the performance.The tests are run on ther glusterFS mountpoint.They are:
1.dd
2.dbench
3.arequal
4.posix_compliance
5.kernel compile
6.fsx
7.ltp tests
8.fileop
9.openssl build
10.postmark
11.ffsb
12.Reading from large file
13.Multiple file creation(100000)
14.glusterfs build 
15.syscallbench
16.tiobench
17.locktests
18.ioblazer";
}

run_ffsb ()
{
    echo "Executing ffsb"
    set +x
    cp $BIN_PATH/system_light/profile_everything $THIS_TEST_DIR/profile_everything
    sed -i "s[/mnt/test1[$THIS_TEST_DIR[" profile_everything
    $SCRIPTS_PATH/ffsb_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing data"
        rm -rfv data && echo "Removed"
        echo "Removing meta" 
        rm -rfv meta && echo "Removed"
        echo "Removing profile_everything"
        rm $FFSB_FILE && echo "Removed"
    else
        echo "ffsb failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_ltp ()
{
    echo "Executing ltp tests"
    set +x
    mkdir ltp
    cd  ltp
    $SCRIPTS_PATH/ltp_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing directory"
        cd -
        rm -rfv ltp && echo "removed"
    else
        echo "ltp failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_fileop ()
{
    echo "Executing fileop"
    set +x
    $SCRIPTS_PATH/fileop_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
    else
        echo "fileop failed"
        echo $CNT
    fi
}

run_kernel_compile ()
{
    echo "Kernel compiling"  #Untars the given kernel file and compiles it
    set +x
    $SCRIPTS_PATH/kernel.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing linux-$VERSION.tar.bz2 and linux-$VERSION"
        rm -r linux-$VERSION* && echo "removed"
    else
        echo "kernel compile failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

# echo "Executing bonnie++"
#  set +x
#  $SCRIPTS_PATH/bonnie_test.sh 
# if [ "${?}" -eq 0 ]; then
#     CNT=$((CNT+1))
#     echo $CNT
# else
#     echo "bonnie failed" | tee -a $TEST_FAIL
#     echo $CNT
# fi

run_dd ()
{
    echo "Executing dd"
    set +x
    $SCRIPTS_PATH/dd_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
    else
        echo "dd failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_read_large ()
{
    echo "Reading from large file"
    set +x
    $SCRIPTS_PATH/read_large.sh
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing $PWD/$OF"
        rm $PWD/$OF && echo "Removed"
    else
        echo "Large file reading failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_dbench ()
{
    echo "Executing dbench"
    set +x
    $SCRIPTS_PATH/dbench_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing clients"
        rm -r clients && echo "Removed"
    else
        echo "dbench failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_glusterfs_build ()
{
    echo "glusterfs build"
    set +x;
    $SCRIPTS_PATH/glusterfs_build.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing glusterfs directory"
        rm -r $GLUSTERFS_DIR && echo "Removed"
    else
        echo "glusterfs build failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_posix_compliance ()
{
    echo "Checking for POSIX compliance" 
    set +x
    $SCRIPTS_PATH/posix_compliance.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing posix created directories and files"
        rm -r fstest* && echo "Removed"
    else
        echo "posix failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_openssl_build ()
{
    echo "Building opnssl"
    set +x
    $SCRIPTS_PATH/open.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing  $OPENSSL_DIR"
        rm -r openssl* && echo "Removed"
    else
        echo "openssl failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_postmark ()
{
    echo "Running postmark"
    set +x
    $SCRIPTS_PATH/postmark.sh
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
    else
        echo "postmark failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_multiple_files ()
{
    echo "Multiple files creation(100000),listing,removal"
    set +x
    $SCRIPTS_PATH/multiple_files.sh
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
    else
        echo "multiple files failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

# echo "Executing iozone"
#  set +x
#  $SCRIPTS_PATH/iozone_test.sh
# if [ "${?}" -eq 0 ]; then
#     CNT=$((CNT+1))
#     echo $CNT
# else
#     echo "iozone failed" | tee -a $TEST_FAIL
#     echo $CNT
# fi

run_fsx ()
{
    echo "Executing fsx"
    set +x
    $SCRIPTS_PATH/fsx_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing $FSX_FILE,$FSX_FILE.fsxgood and $FSX_FILE.fsxlog"
        rm $FSX_FILE* && echo "Removed"
    else
        echo "fsx failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_arequal ()
{
    echo "executing arequal"
    set +x
    $SCRIPTS_PATH/arequal_test.sh 
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        echo "Removing $ARE_DST"
        rm -r $ARE_DST && echo "Removed"
    else
        echo "arequal failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_syscallbench ()
{
    echo "Executing syscallbench"
    set +x
    $SCRIPTS_PATH/syscallbench.sh
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
    else
        echo "syscallbench failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_tiobench ()
{
    echo "Executing tiobench"
    set +x
    $SCRIPTS_PATH/tiobench.sh
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
    else
        echo "tiobench failed" | tee -a $TEST_FAIL
        echo $CNT
    fi
}

run_locktests ()
{
    echo "Executing locktests"
    set +x
    locks_dirname=$(dirname $LOCK_BIN)
    cp $locks_dirname/test $LOCK_TEST_FILE
    $SCRIPTS_PATH/locks.sh
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1))
        echo $CNT
        rm $LOCK_TEST_FILE
    else
        echo "locktests failed" | tee -a $TEST_FAIL
        echo $CNT
        rm $LOCK_TEST_FILE
    fi
}

run_blazer ()
{
    echo "Executing ioblazer";
    set +x;
    $SCRIPTS_PATH/blazer.sh;
    if [ "${?}" -eq 0 ]; then
        CNT=$((CNT+1));
        echo $CNT;
    else
        echo "blazer failed | tee -a $TEST_FAIL";
        echo $CNT;
    fi
}

run_rpc_coverage ()
{
    echo "Executing rpc coverage tests";
    set +x;
    $SCRIPTS_PATH/rpc-fops.sh;
    if [ "${?}" -eq 0 ]; then
	CNT=$((CNT+1));
	echo $CNT;
    else
	echo "rpc-coverage failed | tee -a $TEST_FAIL";
	echo $CNT;
    fi
}
    
main ()
{
    echo " Changing to the specified mountpoint";
    cd $THIS_TEST_DIR;
    pwd;
    sleep 1;
    
    run_rpc_coverage;
    run_posix_compliance;
    run_ffsb;
    run_ltp;
    run_fileop;
    run_kernel_compile;
    run_dd;
    run_read_large;
    run_dbench;
    run_glusterfs_build;
    run_openssl_build;
    run_postmark;
    run_multiple_files;
    run_fsx;
    run_arequal;
    run_syscallbench;
    run_tiobench;
    if [ $TYPE != "nfs" ]; then
	run_locktests;
    fi
    #run_blazer;

    echo "Total $CNT tests were successful" | tee -a $TEST_FAIL

    if [ "$INVOKEDIR" == "$THIS_TEST_DIR" ]; then
        echo "moving to the parent directory"
        cd ..
        echo "Removing $THIS_TEST_DIR"
        rmdir $THIS_TEST_DIR
        if [ "${?}" -ne 0 ]; then
            echo "rmdir failed:Directory not empty"
        fi
    else
        echo "Switching over to the previous working directory"
        cd $INVOKEDIR
        echo "Removing $THIS_TEST_DIR"
        rmdir $THIS_TEST_DIR
        if [ "${?}" -ne 0 ]; then
            echo "rmdir failed:Directory not empty"
        fi
    fi
}

_init "$@" && main "$@"