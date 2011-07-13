#script to run mixed test on client mount pts
cd CLOUD_MNT_PT

y=`cat /opt/qa/nfstesting/mixedtest`

i=1 #change this value to reuse this file

for y in {1..13};
do
if [ $y -eq 13 ];then
echo "1" > /opt/qa/nfstesting/mixedtest
fi

if [ $y -eq 1 ];then
    tool="iozone"
    echo "2" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -p /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -p `hostname`/$tool/run_$i
    #move to it
    cd `hostname`/$tool/run_$i
    # run iozone
( /opt/qa/tools/32-bit/iozone  -a -b /opt/qa/nfstesting/$tool/log/`hostname`_`date +%h%d%T`_excel.xls > /opt/qa/nfstesting/$tool/log/`hostname`_`date +%h%d%T`_iozone.log ) &

elif [ $y -eq 2 ];then
    tool="dbench"
    echo "3" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -p /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -p `hostname`/$tool/run_$i
    #move to it
    cd `hostname`/$tool/run_$i
    # run dbench
   ( dbench -s 10 -t 18000 > /opt/qa/nfstesting/$tool/log/`hostname`_`date +%h%d%T`_Dbench.log ) &

elif [ $y -eq 3 ];then
    tool="fio"
    echo "4" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -p /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run and move to it
    mkdir -p `hostname`/$tool/run_$i
    cd `hostname`/$tool/run_$i
   ( fio  /opt/qa/nfstesting/$tool/randomread.fio > /opt/qa/nfstesting/$tool/log/`hostname`_`date +%h%d%T`_fio.log ) &

elif [ $y -eq 4 ];then
    tool="fileop"
    echo "5" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -p /opt/qa/nfstesting/$tool/log
    mkdir -p `hostname`/$tool/run_$i
    cd `hostname`/$tool/run_$i
    #( /opt/qa/tools/kernel_compile.sh http://www.kernel.org/pub/linux/kernel/v2.6/testing/linux-2.6.34-rc5.tar.bz2  ) &
    ( (time /opt/qa/tools/32-bit/tars/iozone3_347/src/current/fileop -f 200 -t)  2>&1 | tee -a /opt/qa/nfstesting/$tool/log/`hostname`_`date +%%h%d%T`_fileop.log ) &

elif [ $y -eq 5 ];then
    tool="bonnie"
    echo "6" > /opt/qa/nfstesting/mixedtest   
    #create log directory - if needed.
    mkdir -p /opt/qa/nfstesting/$tool/log
    #adduser gluster
    mkdir -p `hostname`/$tool/scratch/run_$i
    chmod -R 777 `hostname`/$tool/scratch/run_$i
    ( /opt/qa/tools/32-bit/bonnie/sbin/bonnie++ -u gluster -d `hostname`/bonnie/scratch/run_$i >  /opt/qa/nfstesting/$tool/log/`hostname`_`date +%h%d%T`_bonnie.log ) &
   
elif [ $y -eq 6 ];then
	tool="postmark"
	echo "7" > /opt/qa/nfstesting/mixedtest
	#creat log
	mkdir -p /opt/qa/nfstesting/$tool/log
        mkdir -p CLOUD_MNT_PT/`hostname`/postmark

	#create config file
        echo "set number 10000" > /opt/qa/nfstesting/$tool/log/`hostname`.pm
	echo "set subdirectories 10000" >> /opt/qa/nfstesting/$tool/log/`hostname`.pm
	echo "set location CLOUD_MNT_PT/`hostname`/postmark" >> /opt/qa/nfstesting/$tool/log/`hostname`.pm

	#run postmark
 	( /opt/qa/tools/32-bit/tars/tools.git/postmark/postmark /opt/qa/nfstesting/$tool/log/`hostname`.pm ) &

elif [ $y -eq 7 ];then
        echo "8" > /opt/qa/nfstesting/mixedtest
        #creat log
	(
	mkdir -p CLOUD_MNT_PT/`hostname`/tc9
	cd CLOUD_MNT_PT/`hostname`/tc9
	mkdir -p /opt/qa/nfstesting/tc9
	cd /opt/qa/nfstesting/tc9
	if [ ! -f /opt/qa/nfstesting/tc9/linux-2.6.33.2.tar.bz2 ];
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
	tar -xjf linux-2.6.33.2.tar.bz2
	fi

	mkdir -p CLOUD_MNT_PT/`hostname`/tc9
	cp -R /opt/qa/nfstesting/tc9/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/tc9
	cd /tmp
	#umount CLOUD_MNT_PT
	for k in {1..500};
	do
	
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	tar -c CLOUD_MNT_PT/`hostname`/tc9/linux-2.6.33.2 > CLOUD_MNT_PT/`hostname`/tc9/tarball.tar
	rm -f CLOUD_MNT_PT/`hostname`/tc9/tarball.tar
	#umount CLOUD_MNT_PT
	done
	) &

elif [ $y -eq 8 ];then
        echo "9" > /opt/qa/nfstesting/mixedtest
        #creat log

	mkdir -p /opt/qa/nfstesting/log/tc10
	( for k in {1..5000};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch -o noresvport "  CLOUD_MNT_PT
	df >> /opt/qa/nfstesting/log/tc10/hostname.log
	#umount CLOUD_MNT_PT
	done
	) &


elif [ $y -eq 9 ];then
        echo "10" > /opt/qa/nfstesting/mixedtest
        #creat log
	mkdir -p CLOUD_MNT_PT/`hostname`/tc12
	cd CLOUD_MNT_PT/`hostname`/tc12

	mkdir -p /opt/qa/nfstesting/tc12
	cd /opt/qa/nfstesting/tc12
	(
	if [ ! -f /opt/qa/nfstesting/tc12/linux-2.6.33.2.tar.bz2 ] 
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2 
	tar -xjf linux-2.6.33.2.tar.bz2
	fi
	mkdir -p CLOUD_MNT_PT/`hostname`/tc12
	cd /tmp
	#umount CLOUD_MNT_PT
	for k in {1..100};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	rsync -avz -ignore-times  /opt/qa/nfstesting/tc12/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/tc12
	#umount CLOUD_MNT_PT
	done
	) &
elif [ $y -eq 10 ];then
        echo "11" > /opt/qa/nfstesting/mixedtest
        #creat log
        mkdir -p CLOUD_MNT_PT/`hostname`/tc13
        cd CLOUD_MNT_PT/`hostname`/tc13
	(
	mkdir -p /opt/qa/nfstesting/tc13
	cd /opt/qa/nfstesting/tc13
	if [ ! -f /opt/qa/nfstesting/tc13/linux-2.6.33.2.tar.bz2 ] 
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
	tar -xjf linux-2.6.33.2.tar.bz2
	fi
	mkdir -p CLOUD_MNT_PT/`hostname`/tc13
	cd /tmp
	cp -R /opt/qa/nfstesting/t13/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/tc13
	#umount CLOUD_MNT_PT
	for k in {1..100};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	rsync -avz -ignore-times   CLOUD_MNT_PT/`hostname`/tc13/linux-2.6.33.2 /tmp/rsynctest
	#umount CLOUD_MNT_PT
	rm -rf /tmp/rsynctest
	done
	) &

elif [ $y -eq 11 ];then
        echo "12" > /opt/qa/nfstesting/mixedtest
        #creat log
        mkdir -p CLOUD_MNT_PT/`hostname`/tc17
        cd CLOUD_MNT_PT/`hostname`/tc17

	cd CLOUD_MNT_PT/`hostname`/tc17

	( dbench -D CLOUD_MNT_PT/`hostname`/tc17 -t 86400 ) &

elif [ $y -eq 12 ];then
        echo "13" > /opt/qa/nfstesting/mixedtest
        #creat log
        mkdir -p CLOUD_MNT_PT/`hostname`/tc4
        cd CLOUD_MNT_PT/`hostname`/tc4

	(
	mkdir -p /opt/qa/nfstesting/tc4
	cd /opt/qa/nfstesting/tc4
	if [ ! -f /opt/qa/nfstesting/tc4/linux-2.6.33.2.tar.bz2 ] 
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
	tar -xjf linux-2.6.33.2.tar.bz2
	fi
	mkdir -p CLOUD_MNT_PT/`hostname`/tc4
	cd /tmp
	#umount CLOUD_MNT_PT
	for k in {1..1000};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	cp -R /opt/qa/nfstesting/tc4/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/tc4
	find CLOUD_MNT_PT/`hostname`/tc4
	rm -rf CLOUD_MNT_PT/`hostname`/tc4/*
	#umount CLOUD_MNT_PT
	done
	) &

fi
done
