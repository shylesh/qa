cd CLOUD_MNT_PT
i="870"
#fileop,dbench - 
#IOzone
    tool="iozone"
    echo "2" > /opt/qa/nfstesting/mixedtest
    #create LoG directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/LoG
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run iozone
   CMD="/opt/qa/tools/32-bit/iozone  -a -b /opt/qa/nfstesting/iozone/LoG/`hostname`_`date +%h%d%T`_excel.xls 2>&1 /opt/qa/nfstesting/iozone/LoG/`hostname`_`date +%h%d%T`_iozone.LoG "

    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

    ( $CMD ) &

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

	

#dbench
    tool="dbench"
    echo "3" > /opt/qa/nfstesting/mixedtest
    #create LoG directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/LoG
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run dbench

   CMD="dbench -s 10 -t 18000  > /opt/qa/nfstesting/dbench/LoG/`hostname`_`date +%h%d%T`_Dbench.LoG "

    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

    #( $CMD ) &

     ( dbench -s 10 -t 18000  > /opt/qa/nfstesting/dbench/LoG/`hostname`_`date +%h%d%T`_Dbench.LoG ) &

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

#fio
    tool="fio"
    echo "4" > /opt/qa/nfstesting/mixedtest
    #create LoG directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/LoG
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run fio

    CMD="fio  /opt/qa/nfstesting/fio/randomread.fio > /opt/qa/nfstesting/fio/LoG/`hostname`_`date +%h%d%T`_fio.LoG "

    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

    ( fio  /opt/qa/nfstesting/fio/randomread.fio > /opt/qa/nfstesting/fio/LoG/`hostname`_`date +%h%d%T`_fio.LoG ) &  

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

#fileop
    tool="fileop"
    echo "5" > /opt/qa/nfstesting/mixedtest
    #create LoG directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/LoG
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run fileop

CMD="( (time /opt/qa/tools/32-bit/tars/iozone3_347/src/current/fileop -f 100 -t)  2>&1 | tee -a /opt/qa/nfstesting/$tool/LoG/`hostname`_`date +%h%d%T`_fileop.LoG )"
    echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
    ( (/opt/qa/tools/32-bit/tars/iozone3_347/src/current/fileop -f 100 -t)  2>&1 | tee -a /opt/qa/nfstesting/fileop/LoG/`hostname`_`date +%h%d%T`_fileop.LoG ) &

    echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG


#bonnie
    tool="bonnie"
    echo "5" > /opt/qa/nfstesting/mixedtest
    #create LoG directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/LoG
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_bon/dir
    #move to it
    cd  $WRKPATH/$tool/
    # run bonnie

	CMD="( ( /opt/qa/tools/32-bit/bonnie/sbin/bonnie++ -u `whoami` -d run_bon/dir ) 2>&1 | tee -a /opt/qa/nfstesting/bonnie/LoG/`hostname`_`date +%h%d%T`_bonnie.LoG )"

	echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

( ( /opt/qa/tools/32-bit/bonnie/sbin/bonnie++ -u `whoami` -d run_bon/dir ) 2>&1 | tee -a /opt/qa/nfstesting/bonnie/LoG/`hostname`_`date +%h%d%T`_bonnie.LoG ) &

	echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

#postmark
    tool="postmark"
    echo "7" > /opt/qa/nfstesting/mixedtest
    #create LoG directory - if needed.
    mkdir -vp /opt/qa/nfstesting/$tool/LoG
    #create  a directory for tool to run.
    mkdir -vp $WRKPATH/$tool/run_$i
    #move to it
    cd  $WRKPATH/$tool/run_$i
    # run postmark

	FN=`date +%h%d%T`
	echo "set number 10000" > /opt/qa/nfstesting/$tool/LoG/`hostname`_$FN.pm
	echo "set subdirectories 10000" >> /opt/qa/nfstesting/$tool/LoG/`hostname`_$FN.pm
	echo "set location $WRKPATH/$tool/run_$i" >> /opt/qa/nfstesting/$tool/LoG/`hostname`_$FN.pm
        echo "run /tmp/postmark-out">>/opt/qa/nfstesting/$tool/LoG/`hostname`_$FN.pm
	echo "show">>/opt/qa/nfstesting/$tool/LoG/`hostname`_$FN.pm
	echo "quit">>/opt/qa/nfstesting/$tool/LoG/`hostname`_$FN.pm
	export FN
	CMD=" /opt/qa/tools/32-bit/tars/tools.git/postmark/postmark /opt/qa/nfstesting/postmark/LoG/`hostname`_$FN.pm 2>&1 | tee -a /opt/qa/nfstesting/postmark/LoG/`hostname`_`date +%h%d%T`.postmark.LoG"
	echo "~~~~~~>running $tool  at "$WRKPATH/$tool "with command ( $CMD ) &" >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
	( /opt/qa/tools/32-bit/tars/tools.git/postmark/postmark /opt/qa/nfstesting/postmark/LoG/`hostname`_$FN.pm  2>&1 | tee -a  /opt/qa/nfstesting/postmark/LoG/`hostname`_`date +%h%d%T`.postmark.LoG ) &

	echo "~~~~~~>Done.started $tool in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
#nfstestcase-9
    

	(
	echo "8" > /opt/qa/nfstesting/mixedtest
	mkdir -p CLOUD_MNT_PT/`hostname`/Tc9
	cd CLOUD_MNT_PT/`hostname`/Tc9
	mkdir -p /opt/qa/nfstesting/Tc9
	cd /opt/qa/nfstesting/Tc9
	if [ ! -f /opt/qa/nfstesting/Tc9/linux-2.6.33.2.tar.bz2 ];
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
	tar -xjf linux-2.6.33.2.tar.bz2
	fi

	mkdir -p CLOUD_MNT_PT/`hostname`/Tc9
	cp -R /opt/qa/nfstesting/Tc9/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/Tc9
	cd /tmp
	#umount CLOUD_MNT_PT
	for k in {1..500};
	do
	
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	tar -c CLOUD_MNT_PT/`hostname`/Tc9/linux-2.6.33.2 > CLOUD_MNT_PT/`hostname`/Tc9/tarball.tar
	rm -f CLOUD_MNT_PT/`hostname`/Tc9/tarball.tar
	#umount CLOUD_MNT_PT
	done
	) &
 echo "~~~~~~>Done.started nfstestcase-9 in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

#tc10
	 echo "9" > /opt/qa/nfstesting/mixedtest
        #creat LoG

	mkdir -p /opt/qa/nfstesting/LoG/tc10
	( for k in {1..5000};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch -o noresvport "  CLOUD_MNT_PT
	df >> /opt/qa/nfstesting/LoG/tc10/hostname.LoG
	#umount CLOUD_MNT_PT
	done
	) &
echo "~~~~~~>Done.started nfstestcase-10 in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
#Tc12

echo "10" > /opt/qa/nfstesting/mixedtest
        #creat LoG
	mkdir -p CLOUD_MNT_PT/`hostname`/Tc12
	cd CLOUD_MNT_PT/`hostname`/Tc12

	mkdir -p /opt/qa/nfstesting/Tc12
	cd /opt/qa/nfstesting/Tc12
	(
	if [ ! -f /opt/qa/nfstesting/Tc12/linux-2.6.33.2.tar.bz2 ] 
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2 
	tar -xjf linux-2.6.33.2.tar.bz2
	fi
	mkdir -p CLOUD_MNT_PT/`hostname`/Tc12
	cd /tmp
	#umount CLOUD_MNT_PT
	for k in {1..100};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	rsync -avz -ignore-times  /opt/qa/nfstesting/Tc12/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/Tc12
	#umount CLOUD_MNT_PT
	done
	) &
echo "~~~~~~>Done.started nfstestcase-12 in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG

#Tc13
   echo "11" > /opt/qa/nfstesting/mixedtest
        #creat LoG
        mkdir -p CLOUD_MNT_PT/`hostname`/Tc13
        cd CLOUD_MNT_PT/`hostname`/Tc13
	(
	mkdir -p /opt/qa/nfstesting/Tc13
	cd /opt/qa/nfstesting/Tc13
	if [ ! -f /opt/qa/nfstesting/Tc13/linux-2.6.33.2.tar.bz2 ] 
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
	tar -xjf linux-2.6.33.2.tar.bz2
	fi
	mkdir -p CLOUD_MNT_PT/`hostname`/Tc13
	cd /tmp
	cp -R /opt/qa/nfstesting/Tc13/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/Tc13
	#umount CLOUD_MNT_PT
	for k in {1..100};
	do
	mkdir -p /tmp/rsynctest1
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	rsync -avz -ignore-times   CLOUD_MNT_PT/`hostname`/Tc13/linux-2.6.33.2 /tmp/rsynctest1
	#umount CLOUD_MNT_PT
	rm -rf /tmp/rsynctest1
	done
	) &
echo "~~~~~~>Done.started nfstestcase-13 in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
#Tc17
     echo "12" > /opt/qa/nfstesting/mixedtest
        #creat LoG
        mkdir -p CLOUD_MNT_PT/`hostname`/Tc17
        cd CLOUD_MNT_PT/`hostname`/Tc17

	cd CLOUD_MNT_PT/`hostname`/Tc17

	( dbench -D CLOUD_MNT_PT/`hostname`/Tc17 -t 86400 ) &

echo "~~~~~~>Done.started nfstestcase-17 in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
#Tc4
	 echo "13" > /opt/qa/nfstesting/mixedtest
        #creat LoG
        mkdir -p CLOUD_MNT_PT/`hostname`/Tc4
        cd CLOUD_MNT_PT/`hostname`/Tc4

	(
	mkdir -p /opt/qa/nfstesting/Tc4
	cd /opt/qa/nfstesting/Tc4
	if [ ! -f /opt/qa/nfstesting/Tc4/linux-2.6.33.2.tar.bz2 ] 
	then
	wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
	tar -xjf linux-2.6.33.2.tar.bz2
	fi
	mkdir -p CLOUD_MNT_PT/`hostname`/Tc4
	cd /tmp
	#umount CLOUD_MNT_PT
	for k in {1..1000};
	do
	#mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
	cp -R /opt/qa/nfstesting/Tc4/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/Tc4
	find CLOUD_MNT_PT/`hostname`/Tc4
	rm -rf CLOUD_MNT_PT/`hostname`/Tc4/*
	#umount CLOUD_MNT_PT
	done
	) &
echo "~~~~~~>Done.started nfstestcase-4 in bkground"  >> /opt/qa/nfstesting/Tools_status_`hostname`.LoG
