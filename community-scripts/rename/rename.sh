#!/bin/bash

set -e
function main()
{
    mountpt="/mnt/gluster";

    mkdir -p ${mountpt}/rename-testdir;

    cd ${mountpt}/rename-testdir;

    # TODO: get the 'ls -l' of backend also

    # case 1
    echo "============================"
    echo 1 > 1;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 5;
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l;
    cat 5; rm 5;

    echo "----------------------------"
    echo 1 > 1;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 5;
    echo 1 > 1;
    mv 1 5;
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l;
    cat 5; rm 5;


    # case 2
    echo "============================"

    echo 1 > 1;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2;
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l;
    cat 2; rm 2;

    echo "----------------------------"

    echo 1 > 1;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2;
    echo 1 > 1;
    mv 1 2;
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l;
    cat 2; rm 2;

    # case 3
    echo "============================"

    echo 1 > 1;
    echo 55555 > 5;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 5;
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l
    cat 5; rm 5;

    echo "----------------------------"
    echo 1 > 1;
    echo 55555 > 5;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 5;
    echo 1 > 1;
    mv 1 5;
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l
    cat 5; rm 5;

    # case 4;
    echo "============================"

    echo 1 > 1;
    echo 22 > 2;
    mv 2 5;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 5
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l
    cat 5; rm 5;

    echo "----------------------------"
    echo 1 > 1;
    echo 22 > 2;
    mv 2 5;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 5
    echo 1 > 1;
    mv 1 5
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l
    cat 5; rm 5;

    # case 5
    echo "============================"

    echo 1 > 1;
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    echo hello > 1;
    mv 1 2
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l;
    cat 2; rm 2;

    echo "----------------------------"
    echo 1 > 1;
    echo 55555 > 5;
    mv 5 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2
    echo 1 > 1;
    mv 1 2
    ls -l /export/d*/rename-testdir
    echo "on mount"
    ls -l;
    cat 2; rm 2;

    # case 6
    echo "============================"

    echo 1 > 1;
    echo 22 > 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2;
    ls -l /export/d*/rename-testdir
    ls -l
    cat 2; rm 2;
    

    echo "----------------------------"
    echo 1 > 1;
    echo 22 > 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2;
    echo 1 > 1;
    mv 1 2;
    ls -l /export/d*/rename-testdir
    ls -l
    cat 2; rm 2;

    # case 7
    echo "============================"

    echo 1 > 1;
    echo 4444 > 4;
    mv 4 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2
    ls -l /export/d*/rename-testdir
    ls -l
    cat 2; rm 2;

    echo "----------------------------"
    echo 1 > 1;
    echo 4444 > 4;
    mv 4 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 1 2
    echo 1 > 1;
    mv 1 2
    ls -l /export/d*/rename-testdir
    ls -l
    cat 2; rm 2;

    # case 8
    echo "============================"

    echo 1 > 1;
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 5;
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 5; rm 5;

    echo "----------------------------"

    # case 9
    echo "============================"

    echo 1 > 1;
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 3;
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 3; rm 3;
    
    echo "----------------------------"

    # case 10
    echo "============================"
    echo 1 > 1; 
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 4
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 4; rm 4;

    echo "----------------------------"

    # case 11
    echo "============================"
    echo 1 > 1;
    echo 55555 > 5;
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 5
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 5; rm 5;

    echo "----------------------------"

    # case 12
    echo "============================"
    echo 1 > 1;
    echo 333 > 3;
    mv 1 2; mv 3 5;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 5
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 5; rm 5;

    echo "----------------------------"

    # case 13
    echo "============================"
    echo 1 > 1;
    echo 4444 > 4;
    mv 1 2; mv 4 5;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 5
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 5; rm 5;

    echo "----------------------------"

    # case 14
    echo "============================"
    echo 1 > 1;
    echo 55555 > 5;
    mv 1 2; mv 5 3;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 3
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 3; rm 3;

    echo "----------------------------"

    # case 15
    echo "============================"
    echo 1 > 1;
    echo 333 > 3;
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 3
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 3; rm 3;

    echo "----------------------------"

    # case 16
    echo "============================"
    echo 1 > 1;
    echo 4444 > 4
    mv 1 2; mv 4 3;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 3
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 3; rm 3;

    echo "----------------------------"

    # case 17
    echo "============================"
    echo 1 > 1;
    echo 55555 > 5;
    mv 1 2; mv 5 4;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 4
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 4; rm 4;

    echo "----------------------------"

    # case 18
    echo "============================"
    echo 1 > 1;
    echo 333 > 3;
    mv 1 2; mv 3 4;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 4
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 4; rm 4;

    echo "----------------------------"

    # case 19
    echo "============================"
    echo 1 > 1;
    echo 4444 > 4;
    mv 1 2;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 4
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 4; rm 4;

    echo "----------------------------"

    # case 20
    echo "============================"
    echo 1 > 1;
    echo 7777777 > 7;
    mv 1 2; mv 7 4;
    echo "before"
    ls -l /export/d*/rename-testdir
    mv 2 4
    ls -l /export/d*/rename-testdir
    ls -l;
    cat 4; rm 4;

    echo "----------------------------"

}

main "$@"
