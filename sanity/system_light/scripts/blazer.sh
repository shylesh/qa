#!/bin/bash


#ioblazer test which tests the IO functionality, and can generate vm related loads.

function main()
{
    ioblazer -d $BLAZER_DIR;

    # Since opening a file with O_DIRECT in fuse fails check the exit value for failure. If the test fails for the first time assume that
    # the mount point was a fuse mount point and re run the test again with buffered IO enabled.

    if [ $? -ne 0 ]; then
        ioblazer -B 1 -d $BLAZER_DIR
        if [ $? -ne 0 ]; then
            return 11;
        else
            return 0;
        fi
    else
        return 0;
    fi
}

main "$@";