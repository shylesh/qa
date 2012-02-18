#!/bin/bash

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
}

function run_tests ()
{
    local tool=;
    if [ $# -eq 1 ]; then
        tool=$1;
    fi

    export global_test=;

    if [ $tool ]; then
        global_test=$tool;
        export TOOLDIR=$SCRIPTS_PATH/$global_test;

        if [ -f $SCRIPTS_PATH/$tool/$tool.sh ]; then

            echo "executing $tool" && sleep 2;
            set +x;
            $SCRIPTS_PATH/$tool/$tool.sh;
            if [ "${?}" -eq 0 ]; then
                CNT=$((CNT+1))
                echo $CNT
            else
                echo "$tool failed"
                echo $CNT
            fi
            return 0;
        else
            echo "tool $tool is not there in the script directory. Exiting";
            return 22;
        fi
    fi

    for i in $(ls $SCRIPTS_PATH | sort -n) #grep "^[0-9]*$" |
    do
        if [ -f $SCRIPTS_PATH/$i/$i.sh ]; then
            run_tests $i;
            sleep 1;
        fi
    done
}

main ()
{
    echo "Tests available:"
    ls $SCRIPTS_PATH | sort -n && sleep 1;

    old_PWD=$PWD;

    echo "===========================TESTS RUNNING===========================";
    echo "Changing to the specified mountpoint";
    cd $THIS_TEST_DIR;
    pwd;
    sleep 1;

    if [ $TEST == "all" ]; then
        run_tests;
    else
        run_tests $TEST;
        if [ $? -ne 0 ]; then
            cd $old_PWD;
            rmdir $THIS_TEST_DIR;
            exit 22;
        fi
    fi

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