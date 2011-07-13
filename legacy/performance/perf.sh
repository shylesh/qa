#!/bin/bash

perf_test ()
{
    /opt/qa/tools/perf-test.git/perf-test.sh $mount_point | tee -a /export/perf-numbers;
}

iozone_test ()
{
    time iozone -a -f $mount_point/iozone.tmp | tee /export/iozone;
}

bonnie_test ()
{
    time bonnie++ -u root -d $mount_point | tee /export/bonnie;
}

_init ()
{
    mount_point=$1;
}

main ()
{
    perf_test;
    iozone_test;
    bonnie_test;
}


_init "$@" && main "$@";
