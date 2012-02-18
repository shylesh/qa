#!/bin/bash

_init ()
{
    TOTAL=20;
    PASS=0;
}


run_fs_perms_simpletest ()
{
    echo "Executing $LTP_DIR/fs_perms/fs_perms_simpletest.sh"
#cp $LTP_DIR/fs_perms/fs_perms.sh .
    cp $LTP_DIR/fs_perms/fs_perms .
    cp $LTP_DIR/fs_perms/testx .
    time $LTP_DIR/fs_perms/fs_perms_simpletest.sh 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "fs_perms_simpletest failed:$(date +%T)"
        echo $PASS
    fi
}

run_lftest ()
{
    echo "Executing $LTP_DIR/lftest/lftest"
    time $LTP_DIR/lftest/lftest 5000 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "lftest failed:$(date +%T)"
        echo $PASS
    fi
}

run_stream1 ()
{
    echo "Executing $LTP_DIR/stream/stream01"
    time $LTP_DIR/stream/stream01 -c 22 -i 22 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
    else
        echo "stream01 failed:$(date +%T)"
        echo $PASS
    fi
}

run_stream2 ()
{
    echo "Executing $LTP_DIR/stream/stream02"
    time $LTP_DIR/stream/stream02 -c 22 -i 22 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "stream02 failed:$(date +%T)"
        echo $PASS
    fi
}

run_stream3 ()
{
    echo "Executing $LTP_DIR/stream/stream03"
    time $LTP_DIR/stream/stream03 -c 22 -i 22 2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "stream03 failed:$(date +%T)"
        echo $PASS
    fi
}

run_stream4 ()
{
    echo "Executing $LTP_DIR/stream/stream04"
    time $LTP_DIR/stream/stream04 -c 22 -i 22  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "stream04 failed:$(date +%T)"
        echo $PASS
    fi
}

run_stream5 ()
{
    echo "Executing $LTP_DIR/stream/stream05"
    time $LTP_DIR/stream/stream05 -c 22 -i 22  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "stream05 failed:$(date +%T)"
        echo $PASS
    fi
}

run_stream ()
{
    run_stream1;
    run_stream2;
    run_stream3;
    run_stream4;
    run_stream5;
}

run_openfile ()
{
    echo "Executing $LTP_DIR/openfile/openfile"
    time $LTP_DIR/openfile/openfile -f 100 -t 100  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "openfile failed:$(date +%T)"
        echo $PASS
    fi
}

run_inode1 ()
{
    echo "Executing $LTP_DIR/inode/inode01"
    time $LTP_DIR/inode/inode01  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "inode01 failed:$(date +%T)"
        echo $PASS
    fi
}

run_inode2 ()
{
    echo "Executing $LTP_DIR/inode/inode02"
    time $LTP_DIR/inode/inode02  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "inode02 failed:$(date +%T)"
        echo $PASS
    fi
}

run_inode ()
{
    run_inode1;
    run_inode2;
}

run_ftest1 ()
{
    echo "Executing $LTP_DIR/ftest/ftest01"
    time $LTP_DIR/ftest/ftest01  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest01 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest2 ()
{
    echo "Executing $LTP_DIR/ftest/ftest02"
    time $LTP_DIR/ftest/ftest02  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest02 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest3 ()
{
    echo "Executing $LTP_DIR/ftest/ftest03"
    time $LTP_DIR/ftest/ftest03  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest03 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest4 ()
{
    echo "Executing $LTP_DIR/ftest/ftest04"
    time $LTP_DIR/ftest/ftest04  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest04 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest5 ()
{
    echo "Executing $LTP_DIR/ftest/ftest05"
    time $LTP_DIR/ftest/ftest05  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest05 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest6 ()
{
    echo "Executing $LTP_DIR/ftest/ftest06"
    time $LTP_DIR/ftest/ftest06  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest06 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest7 ()
{
    echo "Executing $LTP_DIR/ftest/ftest07"
    time $LTP_DIR/ftest/ftest07  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest07 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest8 ()
{
    echo "Executing $LTP_DIR/ftest/ftest08"
    time $LTP_DIR/ftest/ftest08  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "ftest08 failed:$(date +%T)"
        echo $PASS
    fi
}

run_ftest ()
{
    run_ftest1;
    run_ftest2;
    run_ftest3;
    run_ftest4;
    run_ftest5;
    run_ftest6;
    run_ftest7;
    run_ftest8;
}

run_fsstress ()
{
    echo "Executing $LTP_DIR/fsstress/fsstress"
    time $LTP_DIR/fsstress/fsstress -d $THIS_TEST_DIR -l 22 -n 22 -p 22  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "fsstress failed:$(date +%T)"
        echo $PASS
    fi
}

run_fs_inod ()
{
    echo "Executing $LTP_DIR/fs_inod/fs_inod"
    time $LTP_DIR/fs_inod/fs_inod $THIS_TEST_DIR 22 22 22  2>>$LOG_FILE 1>>$LOG_FILE

    if [ $? -eq 0 ]; then
        let PASS=$PASS+1
        echo $PASS
    else
        echo "fs_inod failed:$(date +%T)"
        echo $PASS
    fi
}

main ()
{
    echo "start ltp tests:$(date +%T)";
    run_fs_perms_simpletest;
    run_lftest;
    run_stream;
    run_openfile;
    run_inode;
    run_ftest;
    run_fsstress;
    run_fs_inod;
    echo "end ltp tests: $(date +%T)";
    echo "total $PASS tests were successful out of $TOTAL tests"
}

_init && main "$@"