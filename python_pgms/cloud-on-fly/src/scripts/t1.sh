cd CLOUD_MNT_PT
i="300"
WRKPATH="CLOUD_MNT_PT/`hostname`"
mkdir -p $WRKPATH
#fileop,dbench - 
#IOzone
    tool="iozone"
    echo "2" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run iozone
   CMD="/opt/qa/tools/32-bit/iozone  -a -b /opt/qa/nfstesting/iozone/log/`hostname`_`date +%h%d%T`_excel.xls 2>&1 /opt/qa/nfstesting/iozone/log/`hostname`_`date +%h%d%T`_iozone.log "

    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/tools_status_`hostname`.log

    ( $CMD ) &

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log

	

#dbench
    tool="dbench"
    echo "3" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run dbench

   CMD="dbench -s 10 -t 60  > /opt/qa/nfstesting/dbench/log/`hostname`_`date +%h%d%T`_Dbench.log "

    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/tools_status_`hostname`.log

    #( $CMD ) &

     ( dbench -s 10 -t 60  > /opt/qa/nfstesting/dbench/log/`hostname`_`date +%h%d%T`_Dbench.log ) &

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log

#fio
    tool="fio"
    echo "4" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run fio

    CMD="fio  /opt/qa/nfstesting/fio/randomread.fio > /opt/qa/nfstesting/fio/log/`hostname`_`date +%h%d%T`_fio.log "

    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/tools_status_`hostname`.log

    ( fio  /opt/qa/nfstesting/fio/randomread.fio > /opt/qa/nfstesting/fio/log/`hostname`_`date +%h%d%T`_fio.log ) &  

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log

#fileop
    tool="fileop"
    echo "5" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run fileop

CMD="( (time /opt/qa/tools/32-bit/tars/iozone3_347/src/current/fileop -f 10 -t)  2>&1 | tee -a /opt/qa/nfstesting/$tool/log/`hostname`_`date +%h%d%T`_fileop.log )"
    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/tools_status_`hostname`.log
    ( (/opt/qa/tools/32-bit/tars/iozone3_347/src/current/fileop -f 10 -t)  2>&1 | tee -a /opt/qa/nfstesting/fileop/log/`hostname`_`date +%h%d%T`_fileop.log ) &

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log


#bonnie
    tool="bonnie"
    echo "5" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_bon/dir
    #move to it
    cd  $WRKPATH/$tool/
    # run bonnie

	CMD="( ( /opt/qa/tools/32-bit/bonnie/sbin/bonnie++ -u `whoami` -d run_bon/dir ) 2>&1 | tee -a /opt/qa/nfstesting/bonnie/log/`hostname`_`date +%h%d%T`_bonnie.log )"

	echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/tools_status_`hostname`.log

( ( /opt/qa/tools/32-bit/bonnie/sbin/bonnie++ -u `whoami` -d run_bon/dir ) 2>&1 | tee -a /opt/qa/nfstesting/bonnie/log/`hostname`_`date +%h%d%T`_bonnie.log ) &

	echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log

#postmark
    tool="postmark"
    echo "7" > /opt/qa/nfstesting/mixedtest
    #create log directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/log
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run postmark

	FN=`date +%h%d%T`
	echo "set number 10000" > /opt/qa/nfstesting/$tool/log/`hostname`_$FN.pm
	echo "set subdirectories 10000" >> /opt/qa/nfstesting/$tool/log/`hostname`_$FN.pm
	echo "set location $WRKPATH/$tool/run_$i" >> /opt/qa/nfstesting/$tool/log/`hostname`_$FN.pm
	export FN
	CMD=" /opt/qa/tools/32-bit/tars/tools.git/postmark/postmark /opt/qa/nfstesting/postmark/log/`hostname`_$FN.pm > > /opt/qa/nfstesting/postmark/log/`hostname`_`date +%h%d%T`.postmark.log"
	echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/tools_status_`hostname`.log
	( /opt/qa/tools/32-bit/tars/tools.git/postmark/postmark /opt/qa/nfstesting/postmark/log/`hostname`_$FN.pm > /opt/qa/nfstesting/postmark/log/`hostname`_`date +%h%d%T`.postmark.log ) &

	echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log
#nfstestcase-9
    

	(
	echo "8" > /opt/qa/nfstesting/mixedtest
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
 echo "~~~~~~>Done.started nfstestcase-9 in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log

#tc10
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
echo "~~~~~~>Done.started nfstestcase-10 in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log
#tc12

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
echo "~~~~~~>Done.started nfstestcase-12 in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log

#tc13
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
	cp -R /opt/qa/nfstesting/tc13/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/tc13
	#umount CLOUD_MNT_PT
	for k in {1..100};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	rsync -avz -ignore-times   CLOUD_MNT_PT/`hostname`/tc13/linux-2.6.33.2 /tmp/rsynctest
	#umount CLOUD_MNT_PT
	rm -rf /tmp/rsynctest
	done
	) &
echo "~~~~~~>Done.started nfstestcase-13 in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log
#tc17
     echo "12" > /opt/qa/nfstesting/mixedtest
        #creat log
        mkdir -p CLOUD_MNT_PT/`hostname`/tc17
        cd CLOUD_MNT_PT/`hostname`/tc17

	cd CLOUD_MNT_PT/`hostname`/tc17

	( dbench -D CLOUD_MNT_PT/`hostname`/tc17 -t 86400 ) &

echo "~~~~~~>Done.started nfstestcase-17 in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log
#tc4
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
echo "~~~~~~>Done.started nfstestcase-4 in bkground"  >> /opt/qa/nfstesting/tools_status_`hostname`.log
