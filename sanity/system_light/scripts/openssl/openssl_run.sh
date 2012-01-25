#!/bin/bash

#This scripts takes openssl tar file,untars it and builds it.

function main()
{
    echo "untarring the openssl tarball"
    echo "start:`date +%T`"
    time tar -xvf $OPENSSL_TAR_FILE 2>>$LOG_FILE 1>>$LOG_FILE
            cd $OPENSSL_DIR

            if [ -z "$PREFIX" -a -z "$OPENSSLDIR" ]; then
                echo "executing ./config:`date +%T`"
                time ./config 2>>$LOG_FILE 1>>$LOG_FILE
                if [ $? -ne 0 ]; then
                    echo "./config failed:`date +%T`"
                    return 11;
                fi
            else
                echo "executing ./config with prefix:`date +%T`"
                time ./config --prefix=$PREFIX --openssldir=$OPENSSLDIR 2>>$LOG_FILE 1>>$LOG_FILE
                if [ $? -ne 0 ]; then
                    echo "config prefix failed:`date +%T`"
                    return 11;
                fi
            fi

            echo "executing make:`date +%T`"
            time make 2>>$LOG_FILE 1>>$LOG_FILE
            if [ $? -ne 0 ]; then
                echo "make failed:`date +%T`"
                return 11
            fi

            echo "executing make test:`date +%T`"
            time make test 2>>$LOG_FILE 1>>$LOG_FILE
            if [ $? -ne 0 ]; then
                echo "make test failed:`date +%T`"
                return 11;
            else
                return 0;
            fi
}

main "$@";
