#!/bin/bash

ulimit -c unlimited
set -x

#set -u
export PATH=$PATH:/opt/qa/tools:/usr/local/bin:/usr/local/sbin

WORKSPACE_DIR="/opt/users/nightly_sanity_valgrind/glusterfs"
WORKDIR="/mnt/nightly_valgrind"
translator=$1
VOLNAME=$translator
SPECDIR="/etc/glusterd/vols/$VOLNAME"
BUILDDIR="$WORKSPACE_DIR/build"

LOGDIR="$WORKDIR/logs_$translator/`date +%F`"
EXPORTDIR=$WORKDIR/data
MOUNTDIR=$WORKDIR/mount/$translator
RESULTDIR=/tmp/nightly_valgrind-results
SYSCALLDIR="$WORKDIR/syscall"
COREDIR="$WORKDIR/$translator"
CORE_REPOSITORY="/opt/cores"

echo "$COREDIR/core" > /proc/sys/kernel/core_pattern

#EMAIL="dl-qa@gluster.com"
EMAIL="lakshmipathi@shell.gluster.com:/home/lakshmipathi/nightly_valgrind/"
RFILE="lakshmipathi@shell.gluster.com:/home/lakshmipathi/resultfile/"
BINDIR="/opt/glusterfs/nightly_valgrind"
TOOLDIR="/opt/qa/tools/tools.git/syscallbench"
#WORKSPACE_DIR="/home/gluster/laks/new/glusterfs/"
#WORKDIR="/mnt/nightly"
#SPECDIR="/opt/users/vijay/nightly"
#BUILDDIR="$WORKSPACE_DIR/build"

#LOGDIR="$WORKDIR/logs/`date +%F`" 
#EXPORTDIR=$WORKDIR/data
#MOUNTDIR=$WORKDIR/mount
#RESULTDIR=/tmp/nightly-results

#EMAIL="lakshmipathi@gluster.com"
#BINDIR="/home/gluster/laks/new/glusterfs/build/build"

VALGRIND="valgrind   --error-limit=no --leak-check=full  --show-reachable=yes --log-file="

function update_git ()
{
        cd $WORKSPACE_DIR
	echo "$WORKSPACE_DIR in there"
        git pull
}

function prepare_dirs()
{
        if [ ! -d $EXPORTDIR ]
        then
                mkdir -p $EXPORTDIR;
        fi

        if [ ! -d $MOUNTDIR ]
        then
                mkdir -p $MOUNTDIR
        fi

    
	j=0;
        #Create individual export_dirs
	#cd $SPECDIR
        #for i in `ls server*.vol`
        #do
         #       let "j += 1"
          #      mkdir -p $EXPORTDIR/export$j
        #done

        #j=0
        #for i in `ls client*.vol`
        #do
         #       let "j += 1"
          #      mkdir -p $MOUNTDIR/client$j
        #done

        if [ ! -d $LOGDIR ]
        then
                mkdir -p $LOGDIR
        fi
	
	if [ ! -d $SYSCALLDIR ]
	then
	        mkdir -p $SYSCALLDIR
	fi

	if [ ! -d $COREDIR ]
	then
	        mkdir -p $COREDIR
        fi
}

function install_glusterfs()
{
    
        cd $WORKSPACE_DIR
        ./autogen.sh;
	make distclean
        if [ ! -d $BUILDDIR ]
        then
                mkdir $BUILDDIR;
        fi
        #cd $BUILDDIR;	
#	make clean -j 32;
        export CFLAGS="-g -O0"
        ./configure --enable-libglusterfsclient  --enable-fusermount --prefix=$BINDIR>/dev/null;
#        ../configure --prefix=$BINDIR>/dev/null;
        make -j 32>/dev/null;
	echo "Post make"
        make install -j 32>/dev/null;

}

function start_glusterfs ()
{
	cd $SPECDIR;
	HOSTNAME=`hostname`
        j=0;
        for i in `ls $VOLNAME.$HOSTNAME*.vol`
        do
                let "j += 1"
                #bname=`basename $i .vol`
		RUN_VALGRIND="$VALGRIND$LOGDIR/$i.val.log"
		( $RUN_VALGRIND $BINDIR/sbin/glusterfsd -f $SPECDIR/$i -l $LOGDIR/$i.log -p $LOGDIR/$i.pid "-N" ) &
		sleep 30
                #$BINDIR/sbin/glusterfsd -f $SPECDIR/$i -l $LOGDIR/$bname$j.log -p $LOGDIR/$bname$j.pid
        done

        j=0
        for i in `ls $VOLNAME-fuse.vol`
        do
                #let "j += 1"
                #bname=`basename $i .vol`
                #$BINDIR/sbin/glusterfs -f $SPECDIR/$i  -l $LOGDIR/$bname$j.log -p $LOGDIR/$bname$j.pid $MOUNTDIR/client$j 
		RUN_VALGRIND="$VALGRIND$LOGDIR/$i.val.log"
		#( $RUN_VALGRIND $BINDIR/sbin/glusterfs -f $SPECDIR/$i  -l $LOGDIR/$i.log -p $LOGDIR/client.pid $MOUNTDIR/client$j "-N" )&
		( $RUN_VALGRIND $BINDIR/sbin/glusterfs -f /etc/glusterd/vols/$translator/$VOLNAME-fuse.vol -l $LOGDIR/$i.log  $MOUNTDIR/client0 "-N" )&
		sleep 40
        done
        
}

function start_nfs_server()
 {
                RUN_VALGRIND="$VALGRIND$LOGDIR/nfs.val.log"
                ( $RUN_VALGRIND $BINDIR/sbin/glusterfs -f /etc/glusterd/nfs/nfs-server.vol -l $LOGDIR/nfs.log  -p $LOGDIR/nfs.pid "-N" )&
                sleep 40
 }
 
 function start_stop_volume(){
 VOLNAME=$1
 $BINDIR/sbin/gluster volume start $VOLNAME
 sleep 3;
 $BINDIR/sbin/gluster --mode=script volume stop $VOLNAME
 }

function run_tests ()
{
        cd $MOUNTDIR/client0;
	#set +e;
	/opt/qa/tools/system_light/run.sh -w $MOUNTDIR/client0 -l /tmp/runlog.$translator
 	#/opt/qa/tools/iozone -a  -s 1024
        x=$?;
        if [ !x ] 
        then
                echo "Sanity Passed!";
        else
                echo "Sanity Failed. Please check your changes!";
        fi
}

function stop_glusterfs()
{
        cd $LOGDIR
        j=0

        #for i in `ls client*.pid`
        #do
         #       let "j += 1"
                umount $MOUNTDIR/client0
		if [ $? -ne 0 ]; then
		    echo "client unmounting failed"
		fi
        #done
        for i in `ls $VOLNAME*.pid`
        do
                cat $i | xargs kill
        done

}

function cleanup()
{

        j=0;
        for i in `ls $SPECDIR | grep server*.vol`
        do
                let "j += 1";
                rm -rfv $EXPORTDIR/export$j
        done

        j=0
        for i in `ls $SPECDIR | grep client*.vol`
        do
                let "j += 1"
                rm -rfv $MOUNTDIR/client$j;
        done
}

function pre_run()
{
        update_git;
        prepare_dirs;
        #set -e;
        install_glusterfs;
}

function send_results()
{
	if [ ! -d $LOGDIR ]
	then
		mkdir $LOGDIR
	fi
        cd $LOGDIR;

	if [ ! -d $RESULTDIR ]
	then
		mkdir $RESULTDIR
	else
		rm -rf $RESULTDIR/*
	fi
	cp $LOGDIR/* $RESULTDIR
	#cp /tmp/runlog.$translator $RESULTDIR
	rm -rf /tmp/runlog.$translator
	mv /tmp/tests_failed $LOGDIR/tests_failed_$translator
	echo $translator >> $LOGDIR/tests_failed_$translator
	
	cnt=`ls -l $COREDIR/core* | wc -l`
	if [ $cnt -gt 2 ]; then
	    echo "core generated for $translator" >> $LOGDIR/tests_failed_$translator
	    mv $COREDIR/core* $CORE_REPOSITORY/core*_$translator_`date +%F`
	fi
	
        tar cfj results_$translator.tar.bz2 $RESULTDIR;
#        mutt -a results_$translator.tgz -s "Sanity Results for `date +%F`" -i $LOGDIR/tests_failed $EMAIL <.;

	scp results_$translator.tar.bz2 $RFILE

 	#git push log files
 	mkdir -p /root/qalogs/sanity_logs/nightly_valgrind/`date +%F`/$translator/
 	cp results_$translator.tar.bz2 /root/qalogs/sanity_logs/nightly_valgrind/`date +%F`/$translator/
 	cd /root/qalogs && git pull && git add . && git commit -a -m "log for `date +%F`" && git push
	scp $LOGDIR/tests_failed_$translator $EMAIL
}

function clean_results()
{
    directory=`date +%F`
    mkdir /tmp/old/$directory -p;
    mv $RESULTDIR/* /tmp/old/$directory
}

function syscallbench_plot()
{
    cp /tmp/`date +%F` $SYSCALLDIR
    cd $SYSCALLDIR 
    mv today yesterday
    ln -s `date +%F` today
    $TOOLDIR/syscallbench-plot today yesterday > $LOGDIR/plot.ps
}
    
    
function post_run()
{
        #set +e;
        stop_glusterfs;
        cleanup;
	#syscallbench_plot;
        send_results;
	clean_results;
}
function start_glusterd()
{
    $BINDIR/sbin/glusterd
    if [ $? -ne 0 ]; then
        echo "glusterd could not be started. Returning"
        return 11;
    else
        echo "glusterd started"
        return 0;
    fi
}
function create_volume ()
{
    vol_type=$1;
    VOLNAME=$1;
    #delete all
    $BINDIR/sbin/gluster --mode=script volume delete afr
    $BINDIR/sbin/gluster --mode=script volume delete dht
    $BINDIR/sbin/gluster --mode=script volume delete stripe
    rm -rf $EXPORTDIR/export[1-4]
    mkdir -p  $EXPORTDIR/export[1-4]
    if [ $vol_type == "dht" ]; then

        echo "Creating the distribute volume";
        $BINDIR/sbin/gluster volume create $VOLNAME $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "afr" ]; then
        echo "Creating the replicate volume"
        $BINDIR/sbin/gluster volume create $VOLNAME replica 2 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "stripe" ]; then
        echo "Creating the stripe volume";
        $BINDIR/sbin/gluster volume create $VOLNAME stripe 4 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi    
	$BINDIR/sbin/gluster volume start $VOLNAME
	killall glusterfs glusterfsd

}
function stop_glusterd()
{
killall glusterd
}
function edit_client_volfile()
{
translator=$1
awk -v port=8000 '{print} /option remote-host dev-sanity-test/ {printf("option remote-port %d\n", port++)}' /etc/glusterd/vols/$translator/$translator-fuse.vol > /tmp/$translator-fuse.vol
cp /tmp/$translator-fuse.vol /etc/glusterd/vols/$translator/
}

function edit_server_volfile()
{
translator=$1
HOSTNAME=`hostname`
FNAME="/etc/glusterd/vols/$translator/$translator.$HOSTNAME.mnt-nightly_valgrind"
#.dev-sanity-test.mnt-nightly_valgrind-data-export1.vol
if [ $translator == afr ];
then
awk -v port=8000 '{print} /option transport-type tcp/ {printf("option transport.socket.listen-port %d\n", port++)}' $FNAME"-data-export1.vol" > /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export1.vol
rm -rf $FNAME"-data-export1.vol"
cp /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export1.vol /etc/glusterd/vols/$translator/

awk -v port=8001 '{print} /option transport-type tcp/ {printf("option transport.socket.listen-port %d\n", port++)}' $FNAME"-data-export2.vol" > /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export2.vol
rm -rf $FNAME"-data-export2.vol"
cp /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export2.vol /etc/glusterd/vols/$translator/
else #for dht or stripe
awk -v port=8000 '{print} /option transport-type tcp/ {printf("option transport.socket.listen-port %d\n", port++)}' $FNAME"-data-export1.vol" > /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export1.vol
rm -rf $FNAME"-data-export1.vol"
cp /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export1.vol /etc/glusterd/vols/$translator/

awk -v port=8001 '{print} /option transport-type tcp/ {printf("option transport.socket.listen-port %d\n", port++)}' $FNAME"-data-export2.vol" > /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export2.vol
rm -rf $FNAME"-data-export2.vol"
cp /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export2.vol /etc/glusterd/vols/$translator/

awk -v port=8002 '{print} /option transport-type tcp/ {printf("option transport.socket.listen-port %d\n", port++)}' $FNAME"-data-export3.vol" > /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export3.vol
rm -rf $FNAME"-data-export3.vol"
cp /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export3.vol /etc/glusterd/vols/$translator/

awk -v port=8003 '{print} /option transport-type tcp/ {printf("option transport.socket.listen-port %d\n", port++)}' $FNAME"-data-export4.vol" > /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export4.vol
rm -rf $FNAME"-data-export4.vol"
cp /tmp/$translator.`hostname`-mnt-nightly_valgrind-data-export4.vol /etc/glusterd/vols/$translator/
fi
}
function edit_nfs_volfile()
 {
 awk -v port=8000 '{print} /option remote-host dev-sanity-test/ {printf("option remote-port %d\n", port++)}' /etc/glusterd/nfs/nfs-server.vol > /tmp/nfs-server.vol
 cp /tmp/nfs-server.vol /etc/glusterd/nfs/
 }
function main()
{
        echo "In main";
	translator=$1
        #trap "post_run" INT TERM EXIT;
        pre_run;
	start_glusterd;
	create_volume $translator;
        ####In order to get NFS vol files ,we need to start the volume and stop it
        start_stop_volume $translator;
 	edit_nfs_volfile;

	edit_client_volfile $translator;
	edit_server_volfile $translator;
	stop_glusterd
        start_glusterfs;
	start_nfs_server;
	df
        run_tests; 
        #trap - INT TERM EXIT
        post_run;
}


#check for command line arg.
if [ ! $# -eq 1 ]
then
echo "Usage: nightly_valgrind.sh afr/dht/stripe";
exit;
fi

main "$@"

