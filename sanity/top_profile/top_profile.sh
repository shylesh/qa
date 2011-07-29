#!/bin/bash

#The script assumes that 'glusterd' is running in all the machines which would become part of the cluster.
#If 'glusterd'is not running, please stop the script run glusterd and then re-execute the script.Script doen not check if 'glusterd'is running or not. 
#The script should be executed from the machine which would be part of the cluster.
#This script takes care of creating volumes and staring them. It aslo takes care of doing operations on them. 

if [ $# -ne 2 ];then
	echo "Usage: $0 <host1> <host2>"
	exit 111;
fi

assert_success ()
{
	if [ $1 -eq 0 ];then
		echo "PASS"
	else
		echo "FAIL"
	fi
}

assert_failure ()
{
	if [ $1 -ne 0 ];then
		echo "PASS"
	else
		echo "FAIL"
	fi
}

host1=$1;
host2=$2;

echo "KEY: peer probing and volume creation Tests";

gluster peer probe $host1;
echo "probing $host1: $(assert_success $?)";

gluster peer probe $host2;
echo "probing $host2: $(assert_success $?)";

gluster volume create hosdu $host1:/tmp/brick1 $host2:/tmp/brick2
echo "Creating volume: $(assert_success $?)";

gluster volume start hosdu 
echo "Starting volume: $(assert_success $?)";

echo "KEY: basic profile tests (profile start|stop|info)";

gluster volume profile hosdu start
echo "start profiling: $(assert_success $?)";
sleep 5; #This sleep is for all the bricks to come online(up).

gluster volume profile hosdu info
echo "profile info: $(assert_success $?)";

gluster volume profile hosdu stop
echo "stop profiling: $(assert_success $?)";

gluster volume profile hosdu stop
echo "stop profiling agian: $(assert_failure $?)";

gluster volume profile hosdu start
echo "start profiling: $(assert_success $?)";

gluster volume profile hosdu start
echo "start profile again: $(assert_failure $?)";

gluster volume profile hosdu stop
echo "stop profile: $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info: $(assert_failure $?)";

gluster volume stop hosdu --mode=script
echo "stopping volume: $(assert_success $?)";

gluster volume profile hosdu start
echo "profile stop after volume stop: $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info after volume stop: $(assert_failure $?)";

gluster volume start hosdu
echo "re-starting volume: $(assert_success $?)";

gluster volume profile hosdu start
echo "re-starting profile: $(assert_failure $?)";

gluster volume stop hosdu --mode=script
echo "stopping volume again: $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info: $(assert_failure $?)";

gluster volume start hosdu
sleep 5; #This time is for all the bricks to come online(up).

gluster volume profile hosdu stop
echo "stopping profile: $(assert_success $?)";

echo "KEY: profile tests after volume set instead of profile start";

gluster volume set hosdu count-fop-hits on
echo "set 'count-fop-hits': $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info: $(assert_failure $?)";

gluster volume set hosdu latency-measurement on
echo "set 'latency-measurement': $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info: $(assert_success $?)";

gluster volume reset hosdu
echo "reset volume option: $(assert_success $?)";

gluster volume set hosdu latency-measurement on
echo "set 'latency-measurenent': $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info: $(assert_failure $?)";

gluster volume set hosdu count-fop-hits on
echo "set count-fop-hits': $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info: $(assert_success $?)";

gluster volume profile hosdu stop 
echo "profile stop: $(assert_success $?)";

gluster volume profile hosdu info
echo "profile info after profile stop: $(assert_failure $?)";

gluster volume profile hosdu start
echo "profile start: $(assert_success $?)";


gluster volume profile hosdu info | grep "nan"
echo "'grep'ing for 'nan' in profile info: $(assert_failure $?)";

echo "KEY: tests after writing data on the mount point";

mount -t glusterfs $host1:hosdu /mnt/

for i in {1..20}
do
	dd if=/dev/zero of=/mnt/$i bs=128K count=10 2>/dev/null 1>/dev/null
	dd if=/mnt/$i of=/dev/null bs=128K count=10 2>/dev/null 1>/dev/null  
done

umount /mnt/

gluster volume profile hosdu info | grep "brick1"
echo "'grep'ing for brick1 in profile info: $(assert_success $?)";

gluster volume profile hosdu info | grep "brick2"
echo "'grep'ing for bruck2 in profile info: $(assert_success $?)";


temp=`gluster volume profile hosdu info | grep "Interval 5 Stats:" | wc -l`
if [ $temp -eq 2 ];then
	echo "'grep'ing for Interval 5 stats: $(assert_success 0)";
else
	echo "'grep'ing for Interval 5 stats: $(assert_success 1)";
fi

echo "KEY: profile tests after add-brick and rebalance";

gluster volume add-brick hosdu $host1:/tmp/brick3/
echo "adding brick3 to volume: $(assert_success $?)";

sleep 5; #This sleep time is for brick3 to come up.

gluster volume profile hosdu info | grep "brick3"
echo "grep for brick3 in profile info after add-brick: $(assert_success $?)";

gluster volume rebalance hosdu start | grep "starting rebalance on volume hosdu has been successful"
echo "rebalance after add-brick: $(assert_success $?)";

temp=0;
while [ $temp -eq 0 ]
do
	temp=`gluster volume rebalance hosdu status | grep "rebalance completed" | wc -l`
done

gluster volume profile hosdu info | grep "Interval 1 Stats"
echo "grep for Interval 1 stats in profile info: $(assert_success $?)";

gluster volume info | grep "count-fop-hits" 
echo "grep for count-fop-hits in volume info: $(assert_success $?)";

gluster volume info | grep "latency-measurement" 
echo "grep for latency-measurement in volume info: $(assert_success $?)";

gluster volume profile hosdu stop
echo "stop profiling: $(assert_success $?)";

gluster volume info | grep "count-fop-hits" 
echo "grep for count-fop-hits after profile stop: $(assert_failure $?)";

gluster volume info | grep "latency-measurement" 
echo "grep for latency-measurement after profile stop: $(assert_failure $?)";

echo "KEY: profile tests after remove-brick";

gluster volume remove-brick hosdu $host1:/tmp/brick1/ --mode=script
echo "remove-brick brick1: $(assert_success $?)";

gluster volume profile hosdu start
echo "start profiling: $(assert_success $?)";
sleep 5; 

gluster volume profile hosdu info | grep "brick1"
echo "grep for brick1 in profile info: $(assert_failure $?)";

gluster volume profile hosdu info | grep "brick2"
echo "grep for brick2: $(assert_success $?)";

gluster volume profile hosdu info | grep "brick3"
echo "grep for brick3: $(assert_success $?)";

echo "KEY: profile tests after replace-brick";

gluster volume replace-brick hosdu $host1:/tmp/brick3/ $host2:/tmp/brick4/ start
echo "replace-brick start from brick3 to brick4: $(assert_success $?)";

temp=0;
count=0;
while [ $temp -eq 0 ]&&[ $count -ne 10 ]
do
	temp=`gluster volume replace-brick hosdu $host1:/tmp/brick3/ $host2:/tmp/brick4/ status | grep "Migration complete" | wc -l`;
	sleep 3;
	let count++;
done

if [ $temp -eq 0 ];then
	echo "KEY: Replace-brick failed"
else
	echo "KEY: Replace-brick Migration Completed"
fi

gluster volume profile hosdu info | grep "brick4"
assert_failure $?;

gluster volume replace-brick hosdu $host1:/tmp/brick3/ $host2:/tmp/brick4/ commit
assert_success $?;
sleep 4;

gluster volume profile hosdu info | grep "brick4"
assert_success $?;

gluster volume stop  hosdu --mode=script
assert_success $?;

gluster volume profile hosdu info
assert_failure $?;

gluster volume start hosdu
assert_success $?;
sleep 4;

gluster volume profile hosdu info
assert_success $?;

gluster volume stop hosdu --mode=script 
assert_success $?;

#gluster volume delete hosdu --mode=script 
#assert_success $?;

echo "KEY: profile tests complete"

#######################################################################################################################################
#							TOP OPERATIONS
#######################################################################################################################################

echo "KEY: volume top tests"

gluster volume start hosdu
assert_success $?;

mount -t glusterfs $host1:hosdu /mnt/

rm -rf /mnt/* #host2:brick2 and host2:brick4 are there in the volume from here on
for i in {1..100}
do
	dd if=/dev/zero of=/mnt/$i bs=128K count=100 2>/dev/null 1>/dev/null
	dd if=/mnt/$i of=/dev/null bs=128K count=100 2>/dev/null 1>/dev/null
done

echo "KEY: tests for top open";

gluster volume top hosdu open
assert_success $?;

gluster volume top hosdu open list-cnt 100
assert_success $?;


gluster volume top hosdu open brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu open brick $host2:/tmp/brick4/ list-cnt 50
assert_success $?;

gluster volume top hosdu open list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu open list-cnt 0 
assert_success $?;

gluster volume top hosdu open list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu open list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

echo "KEY: tests for top read";

gluster volume top hosdu read
assert_success $?;

gluster volume top hosdu read list-cnt 100
assert_success $?;


gluster volume top hosdu read brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu read brick $host2:/tmp/brick4/ list-cnt 40 
assert_success $?;

gluster volume top hosdu read list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu read list-cnt 0 
assert_success $?;

gluster volume top hosdu read list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu read list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

echo "KEY: tests for top write";

gluster volume top hosdu write
assert_success $?;

gluster volume top hosdu write list-cnt 100
assert_success $?;


gluster volume top hosdu write brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu write brick $host2:/tmp/brick4/ list-cnt 40 
assert_success $?;

gluster volume top hosdu write list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu write list-cnt 0 
assert_success $?;

gluster volume top hosdu write list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu write list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

echo "KEY: tests for top opendir";

gluster volume top hosdu opendir
assert_success $?;

gluster volume top hosdu opendir list-cnt 100
assert_success $?;

gluster volume top hosdu opendir brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu opendir brick $host2:/tmp/brick4/ list-cnt 40 
assert_success $?;

gluster volume top hosdu opendir list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu opendir list-cnt 0 
assert_success $?;

gluster volume top hosdu opendir list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu opendir list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

echo "KEY: test for top readdir";

gluster volume top hosdu readdir
assert_success $?;

gluster volume top hosdu readdir list-cnt 100
assert_success $?;

gluster volume top hosdu readdir brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu readdir brick $host2:/tmp/brick4/ list-cnt 40 
assert_success $?;

gluster volume top hosdu readdir list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu readdir list-cnt 0 
assert_success $?;

gluster volume top hosdu readdir list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu readdir list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

echo "KEY:tests for top write-perf"

gluster volume top hosdu write-perf
assert_success $?;

gluster volume top hosdu write-perf list-cnt 100
assert_success $?;


gluster volume top hosdu write-perf brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu write-perf brick $host2:/tmp/brick4/ list-cnt 40 
assert_success $?;

gluster volume top hosdu write-perf list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu write-perf list-cnt 0 
assert_success $?;

gluster volume top hosdu write-perf list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu write-perf list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

gluster volume top hosdu write-perf bs 1024 count 100 list-cnt 10 
assert_success $?;

gluster volume top hosdu write-perf bs 1024 count 100 list-cnt 10  | grep "Throughput"
assert_success $?;

gluster volume top hosdu write-perf bs ff count 100 | grep "block size should be an integer"
assert_success $?;

gluster volume top hosdu write-perf bs 1024 count ff | grep "count should be an integer"
assert_success $?;

gluster volume top hosdu write-perf bs 0 count 100 | grep "block size should be an integer greater than zero"
assert_success $?;

gluster volume top hosdu write-perf count 0 bs 1024 | grep "count should be an integer greater than zero" 
assert_success $?;

gluster volume top hosdu write-perf bs 278947357438574675467857689456945896758967586746789678957689459675 count 100 brick $host2:/tmp/brick4/ | grep "block size is an invalid number"
assert_success $?;

gluster volume top hosdu write-perf bs 1024 count 1000000000000000000000000000000000000000000000000000000000000000000000 brick $host2:/tmp/brick2/ | grep "count is an invalid number"
assert_success $?;

gluster volume top hosdu write-perf list-cnt 1 bs 2048 brick $host2:/tmp/brick2/ count 100
assert_success $?;

gluster volume top hosdu write-porf list-cnt 4575475 | grep "list-cnt should be between 0 and 100"
assert_failure $?;
 
gluster volume top hosdu write-porf list-cnt 4575475 | grep -i "Usage:"
assert_success $?;

echo "KEY: tests for top read-perf";

gluster volume top hosdu read-perf
assert_success $?;

gluster volume top hosdu read-perf list-cnt 100
assert_success $?;


gluster volume top hosdu read-perf brick $host2:/tmp/brick2/ list-cnt 10
assert_success $?;

gluster volume top hosdu read-perf brick $host2:/tmp/brick4/ list-cnt 40 
assert_success $?;

gluster volume top hosdu read-perf list-cnt 222 | grep "list-cnt should be between 0 to 100"
assert_success $?;

gluster volume top hosdu read-perf list-cnt 0 
assert_success $?;

gluster volume top hosdu read-perf list-cnt 10 brick $host2:/tmp/brick3/
assert_failure $?;

gluster volume top hosdu read-perf list-cnt brick $host2:/tmp/brick2/ 100 | grep -i "Usage:"
assert_success $?;

gluster volume top hosdu read-perf bs 1024 count 100 list-cnt 10 
assert_success $?;

gluster volume top hosdu read-perf bs 1024 count 100 list-cnt 10  | grep "Throughput"
assert_success $?;

gluster volume top hosdu read-perf bs ff count 100 | grep "block size should be an integer"
assert_success $?;

gluster volume top hosdu read-perf bs 1024 count ff | grep "count should be an integer"
assert_success $?;

gluster volume top hosdu read-perf bs 0 count 100 | grep "block size should be an integer greater than zero"
assert_success $?;

gluster volume top hosdu read-perf count 0 bs 1024 | grep "count should be an integer greater than zero" 
assert_success $?;

gluster volume top hosdu read-perf bs 278947357438574675467857689456945896758967586746789678957689459675 count 100 brick $host2:/tmp/brick4/ | grep "block size is an invalid number"
assert_success $?;

gluster volume top hosdu read-perf bs 1024 count 1000000000000000000000000000000000000000000000000000000000000000000000 brick $host2:/tmp/brick2/ | grep "count is an invalid number"
assert_success $?;

gluster volume top hosdu read-perf list-cnt 1 bs 2048 brick $host2:/tmp/brick2/ count 100
assert_success $?;

gluster volume top hosdu read-porf list-cnt 4575475 | grep "list-cnt should be between 0 and 100"
assert_failure $?;
 
gluster volume top hosdu read-porf list-cnt 4575475 | grep -i "Usage:"
assert_success $?;




########################### Run tests after adding brick and removing brick etc #################3

echo "KEY: Tests for volume top after add-brick";

gluster volume add-brick hosdu $host1:/tmp/brick5/ #Now the total number of bricks are brick2 and brick4 is Host2 and brick5 in host1 
assert_success $?;

gluster volume rebalance hosdu start | grep "starting rebalance on volume hosdu has been successful"
assert_success $?;

temp=0;
while [ $temp -eq 0 ]
do
	temp=`gluster volume rebalance hosdu status | grep "rebalance completed" | wc -l`
done

gluster volume top hosdu open brick $host1:/tmp/brick5/
assert_success $?;

gluster volume top hosdu read brick $host1:/tmp/brick5/
assert_success $?;

gluster volume top hosdu write brick $host1:/tmp/brick5/
assert_success $?;

gluster volume top hosdu write-perf brick $host1:/tmp/brick5/ bs 1024 count 100
assert_success $?;

gluster volume top hosdu read-perf brick $host1:/tmp/brick5/ bs 2048 count 10
assert_success $?;

gluster volume top hosdu opendir brick $host1:/tmp/brick5/
assert_success $?;

gluster volume top hosdu readdir brick $host1:/tmp/brick5/
assert_success $?;

echo "KEY: volume top tests after remove-brick";

gluster volume remove-brick hosdu $host2:/tmp/brick2/ --mode=script #keyword: $host1:brick5 $host2:brick4 are bricks from here on
assert_success $?;

gluster volume top hosdu open brick $host2:/tmp/brick2/
assert_failure $?;

gluster volume top hosdu read brick $host2:/tmp/brick2/
assert_failure $?;

gluster volume top hosdu write brick $host2:/tmp/brick2/
assert_failure $?;

gluster volume top hosdu write-perf brick $host2:/tmp/brick2/ bs 1024 count 100
assert_failure $?;

gluster volume top hosdu read-perf brick $host2:/tmp/brick2/ bs 2048 count 10
assert_failure $?;

gluster volume top hosdu opendir brick $host2:/tmp/brick2/ list-cnt 100
assert_failure $?;

gluster volume top hosdu readdir brick $host2:/tmp/brick2/ list-cnt 10
assert_failure $?;

echo "KEY: volume top tests after replace-brick, before commit";

gluster volume replace-brick hosdu $host2:/tmp/brick4/ $host1:/tmp/brick6/ start
echo "replace-brick from brick4 to brick6: $(assert_success $?)";

temp=0;
count=0;
while [ $temp -eq 0 ]&&[ $count -ne 10 ]
do
	temp=`gluster volume replace-brick hosdu $host2:/tmp/brick4/ $host1:/tmp/brick6/ status | grep "Migration complete" | wc -l`;
	sleep 3;
	let count++;
done

if [ $temp -eq 0 ];then
	echo "KEY: Replace-brick operation failed";
else
	echo "KEY: Replace-brick Migration Complete";
fi

gluster volume top hosdu open brick $host1:/tmp/brick6/
assert_failure $?;

gluster volume top hosdu open brick $host2:/tmp/brick4/
assert_success $?;

gluster volume top hosdu read brick $host1:/tmp/brick6/
assert_failure $?;

gluster volume top hosdu read brick $host2:/tmp/brick4/
assert_success $?;

gluster volume top hosdu write brick $host1:/tmp/brick6/
assert_failure $?;

gluster volume top hosdu write brick $host2:/tmp/brick4/
assert_success $?;

gluster volume top hosdu write-perf brick $host1:/tmp/brick6/ bs 1024 count 100
assert_failure $?;

gluster volume top hosdu write-perf brick $host2:/tmp/brick4/ bs 1024 count 100
assert_success $?;

gluster volume top hosdu read-perf brick $host1:/tmp/brick6/ bs 2048 count 10
assert_failure $?;

gluster volume top hosdu read-perf brick $host2:/tmp/brick4/ bs 2048 count 10
assert_success $?;

gluster volume top hosdu opendir brick $host1:/tmp/brick6/ list-cnt 100
assert_failure $?;

gluster volume top hosdu opendir brick $host2:/tmp/brick4/ list-cnt 100
assert_success $?;

gluster volume top hosdu readdir brick $host1:/tmp/brick6/ list-cnt 10
assert_failure $?;

gluster volume top hosdu readdir brick $host2:/tmp/brick4/ list-cnt 10
assert_success $?;

echo "KEY: volume top tests after replace-brick, after commit";

gluster volume replace-brick hosdu $host2:/tmp/brick4/ $host1:/tmp/brick6/ commit # keyword: $host1:brick6 and $host1:/brick5
assert_success $?;
sleep 4;

gluster volume top hosdu open brick $host1:/tmp/brick6/
assert_success $?;

gluster volume top hosdu open brick $host2:/tmp/brick4/
assert_failure $?;

gluster volume top hosdu read brick $host1:/tmp/brick6/
assert_success $?;

gluster volume top hosdu read brick $host2:/tmp/brick4/
assert_failure $?;

gluster volume top hosdu write brick $host1:/tmp/brick6/
assert_success $?;

gluster volume top hosdu write brick $host2:/tmp/brick4/
assert_failure $?;

gluster volume top hosdu write-perf brick $host1:/tmp/brick6/ bs 1024 count 100
assert_success $?;

gluster volume top hosdu write-perf brick $host2:/tmp/brick4/ bs 1024 count 100
assert_failure $?;

gluster volume top hosdu read-perf brick $host1:/tmp/brick6/ bs 2048 count 10
assert_success $?;

gluster volume top hosdu read-perf brick $host2:/tmp/brick4/ bs 2048 count 10
assert_failure $?;

gluster volume top hosdu opendir brick $host1:/tmp/brick6/ list-cnt 100
assert_success $?;

gluster volume top hosdu opendir brick $host2:/tmp/brick4/ list-cnt 100
assert_failure $?;

gluster volume top hosdu readdir brick $host1:/tmp/brick6/ list-cnt 10
assert_success $?;

gluster volume top hosdu readdir brick $host2:/tmp/brick4/ list-cnt 10
assert_failure $?;

rm -rf /mnt/*

cpwd=`pwd`;

cd /mnt/

for i in {1..101}
do
mkdir dir$i;
cd dir$i;
done

cd $cpwd;

echo "KEY: tests for validating the list count numbers in the volume top";

temp=`gluster volume top hosdu opendir list-cnt 100 | wc -l`
if [ $temp -eq 5 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top hosdu readdir list-cnt 100 | wc -l`
if [ $temp -eq 5 ];then
	assert_success 0;
else
	assert_success 1;
fi

rm -rf /mnt/*;
umount /mnt/;
gluster volume stop hosdu --mode=script
gluster volume delete hosdu --mode=script

gluster volume create another $host1:/tmp/Brick
gluster volume start another 

mount -t glusterfs $host1:another /mnt/

for i in {1..100}
do
	dd if=/dev/zero of=/mnt/$i bs=128K count=100 2>/dev/null 1>/dev/null
	dd if=/mnt/$i of=/dev/null bs=128K count=100 2>/dev/null 1>/dev/null
done

temp=`gluster volume top another open list-cnt 100 | wc -l`
if [ $temp -eq 105 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top another read list-cnt 100 | wc -l`
if [ $temp -eq 104 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top another write list-cnt 100 | wc -l`
if [ $temp -eq 104 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top another write-perf list-cnt 100 | wc -l`
if [ $temp -eq 104 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top another write-perf bs 1024 count 100 list-cnt 100 | wc -l`
if [ $temp -eq 105 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top another read-perf list-cnt 100 | wc -l`
if [ $temp -eq 104 ];then
	assert_success 0;
else
	assert_success 1;
fi

temp=`gluster volume top another read-perf bs 1024 count 100 list-cnt 100 | wc -l`
if [ $temp -eq 105 ];then
	assert_success 0;
else
	assert_success 1;
fi

echo "KEY: volume top tests complete"

#cleaing up the mess
rm -rf /mnt/*
umount /mnt/
gluster volume stop another --mode=script
gluster volume delete another --mode=script

#Ugly Temporary hack. Remove ut as soon as possible
rm -rf /tmp/brick*
rm -rf /tmp/Brick

echo "Sanity for Top/Profile completed. Exiting the script..."

exit 0;

################################# The End #################################################
