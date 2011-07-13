#!/bin/bash

function update_tools()
{ 
    cd $TOOL_DIR
    echo "In $TOOL_DIR"
    git pull
    make
    echo "Switching to previous directory"
    cd -
}

function syscall_test()
{
    $SYSCALL_BIN > $LOG_DIR/`date +%F`
    if [ $? -ne 0 ]; then
        echo "syscall_test failed"
        return 11;
    fi
}

function main()
{
    update_tools;
    echo "start:`date +%T`"
    syscall_test;
    if [ $? -ne 0 ]; then
	echo "end:`date +%T`"
        return 11;
    fi
}

main "$@"
