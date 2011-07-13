#!/bin/bash

ulimit -c unlimited
set -x
set -u
export PATH=$PATH:/opt/qa/tools:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin
echo $PATH;

function _init()
{
    echo "inited";
        arch=$(uname);
    num_clients=1;
    if [ "$arch" == "SunOs" ]; then
        mount_type="nfs";
    else
        mount_type="fuse";
    fi
#    translator="dht";

    while getopts 't:c:m:' option
    do
        case $option in
            t)
                translator="$OPTARG"
                ;;
            c)
                num_clients="$OPTARG"
                ;;
            m)
                mount_type="$OPTARG"
                ;;
            esac
    done

    if [ "$arch" == "SunOs" ]; then
        mount_type="nfs";
    fi

    echo "translator: $translator" && echo "mount type: $mount_type";
    sleep 1;
    DEFAULT_LOGDIR="/usr/local/var/log/glusterfs";
#     if [ $mount_type == "fuse" ]; then
# 	WORKSPACE_DIR="/opt/users/nightly_performance/glusterfs.git";
#     else
# 	if [ $mount_type == "nfs" ]; then
# 	    WORKSPACE_DIR="/opt/users/nfs_performance/glusterfs.git";
# 	else
# 	    echo "Unknown mount type $mount_type. Exiting";
# 	    exit 22;
# 	fi
#     fi

    WORKSPACE_DIR="/root/sanity/glusterfs.git";
	
    WORKDIR="/export/nightly";
    SPECDIR="/opt/users/nightly_sanity/$translator";
    BUILDDIR="$WORKSPACE_DIR/build";
    
    LOGDIR="$WORKDIR/logs_$translator/`date +%F`";
    EXPORTDIR=$WORKDIR/data;
    MOUNTDIR=$WORKDIR/mount;
    RESULTDIR=/export/nightly-results;
    SYSCALLDIR="$WORKDIR/syscall";
    COREDIR="$WORKDIR/$translator";
    CORE_REPOSITORY="/opt/cores_$mount_type/$translator";

    if [ "$arch" == "Linux" ]; then
        echo "$COREDIR/core" > /proc/sys/kernel/core_pattern;
	echo "1" > /proc/sys/kernel/core_uses_pid;
    fi

    #EMAIL="dl-qa@gluster.com"
    EMAIL="raghavendrabhat@shell.gluster.com:/home/raghavendrabhat/nightly_sanity/";
#    EMAIL="raghavendrabhat@gluster.com";
    BINDIR="/opt/glusterfs/nightly";
    TOOLDIR="/opt/qa/tools/tools.git/syscallbench";
    echo "inited all the variables";

}

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


# function update_git ()
# {
#         cd $WORKSPACE_DIR
# 	echo "$WORKSPACE_DIR in there"
#         git pull
# }

function prepare_dirs()
{
        if [ ! -d $EXPORTDIR ]
        then
                mkdir -p $EXPORTDIR;
        fi

        # if [ ! -d $MOUNTDIR ]
        # then
        #         mkdir -p $MOUNTDIR
        # fi

    
	# j=0;
        # #Create individual export_dirs
	# cd $SPECDIR
        # for i in `ls server*.vol`
        # do
        #         let "j += 1"
        #         mkdir -p $EXPORTDIR/export$j
        # done

        # j=0
        # for i in `ls client*.vol`
        # do
        #         let "j += 1"
        #         mkdir -p $MOUNTDIR/client$j
        # done

    if [ "$mount_type" == "both" ]; then
        j=0;
        for i in $(seq 1 $num_clients); do
            let "j+=1";
            mkdir -p $MOUNTDIR/client$j;
        done
        j=0;
        for i in $(seq 1 $num_clients); do
            let "j+=1";
            mkdir -p $MOUNTDIR/nfs_client$j;
        done
    else if [ "$mount_type" == "fuse" ];then
        j=0;
        for i in $(seq 1 $num_clients); do
            let "j+=1";
            mkdir -p $MOUNTDIR/client$j;
        done
    else if [ "$mount_type" == "nfs" ]; then
        j=0;
        for i in $(seq 1 $num_clients); do
            let "j+=1";
            mkdir -p $MOUNTDIR/nfs_client$j;
        done
    else
	echo "Unknown mount type; Please specify one of fuse , nfs or both";
    fi
    fi
    fi

    if [ ! -d $LOGDIR ]; then
        mkdir -p $LOGDIR;
    fi
    
    if [ ! -d $SYSCALLDIR ]; then
	mkdir -p $SYSCALLDIR;
    fi
    
    if [ ! -d $COREDIR ]; then
	mkdir -p $COREDIR;
    fi

    if [ ! -d $CORE_REPOSITORY ]; then
	mkdir -p $CORE_REPOSITORY;
    fi
}

function install_glusterfs()
{
    cd $WORKSPACE_DIR
    ./autogen.sh;
    if [ ! -d $BUILDDIR ]
    then
        mkdir $BUILDDIR;
    fi
    cd $BUILDDIR;
    
    if [ "$arch" == "Linux" ]; then
	make clean -j 32;
        export CFLAGS="-g -O0 -DDEBUG";
        ../configure CFLAGS="-g -O0 -DDEBUG" --enable-fusermount;
        make -j 32>/dev/null;
	echo "Post make";
        make install -j 32>/dev/null;
    else if [ "$arch" == "SunOs" ]; then
        make clean;
        export CFLAGS="-g -O0 -m64";
        ../configure --prefix=$BINDIR >/dev/null;
        make >/dev/null;
        echo "Post make";
        make install >/dev/null;
    fi
    fi
}

function start_glusterd ()
{
    glusterd -LDEBUG
    if [ $? -ne 0 ]; then
        echo "glusterd could not be started. Returning"
        return 11;
    else
        echo "glusterd started"
        return 0;
    fi
}

function volume_create ()
{
    vol_type=$1;
    if [ $vol_type == "dht" ]; then
        echo "Creating the distribute volume";
        gluster volume create vol $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "afr" ]; then
        echo "Creating the replicate volume"
        gluster volume create vol replica 2 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "stripe" ]; then
        echo "Creating the sttipe volume";
        gluster volume create vol stripe 4 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi    
}

function start_volume()
{
    echo "Starting the volume";
    gluster volume start vol;
    if [ $? -ne 0 ]; then
        echo "gluster volume start failed. Check glusterd log file"
        return 11;
    else
        return 0;
    fi
}

function mount_volume ()
{
    echo "Started the volume. Mounting it"
    if [ $mount_type == "fuse" ]; then	
	modprobe fuse;
        if [ $? -ne  0 ]; then
            echo "loading fuse module failed. Returning";
            return 11;
        fi

        for i in $(seq 1 $num_clients)
        do
            #mount -t glusterfs $(hostname):vol $MOUNTDIR/client$i
            glusterfs --volfile-server=$(hostname) --volfile-id=vol $MOUNTDIR/client$i;
	    df -h; #to be removed
        done
    fi
   
    if [ $mount_type == "nfs" ]; then
        sleep 2;
        gluster volume info;
        sleep 2;
        showmount -e | grep "vol";
        success=$?;
        if [ $success -ne 0 ]; then
            echo "NFS server has not been started. There may be some problem while starting the volume or kernel nfs server may be running.";
            return 11;
        fi
        for i in $(seq 1 $num_clients)
        do
            mount $(hostname):vol $MOUNTDIR/nfs_client$i
        done
    fi

    if [ $mount_type == "both" ]; then
	modprobe fuse;
        if [ $? -ne 0 ]; then
            ret=22;
            echo "loading fuse module failed. Continuing with nfs";
        else
            ret=0;
        fi
        for i in $(seq 1 $num_clients)
        do 
            #mount -t glusterfs $(hostname):vol $MOUNTDIR/client$i
            if [ $ret -eq 0 ]; then
                glusterfs --volfile-server=$(hostname) --volfile-id=vol $MOUNTDIR/client$i;
            fi

            sleep 2;
            gluster volume info;
            sleep 2;
            mount $(hostname):vol $MOUNTDIR/nfs_client$i
        done
    # else
#         echo "Unknown mount type"
#         stop_glusterfs;
#         return 11;
    fi   
}

function start_glusterfs ()
{
    volume_create $translator;
    if [ $? -ne 0 ]; then
        echo "Error while creating the volume exiting.";
        return 11;
    fi
    start_volume;
    if [ $? -ne 0 ]; then
        echo "Error while starting the volume exiting.";
        return 11;
    fi
    mount_volume;
    if [ $? -ne 0 ];then
        if [ $mount_type == "fuse" ] || [ $mount_type == "both" ]; then
            echo "Mounted the volume";
        else
            echo "Error while mounting the volume. Exiting.";
            return 11;
        fi
    else
        echo "Mounted the volume";
    fi
}


function run_tests ()
{
    if [ $mount_type == "fuse" ]; then
        cd $MOUNTDIR/client1;
    fi
    
    if [ $mount_type == "nfs" ]; then
	cd $MOUNTDIR/nfs_client1;
    fi
    
        set +e;
        if [ "$arch" == "SunOs" ] || [ "$mount_type" == "nfs" ]; then
	    /opt/qa/tools/performance/perf.sh $MOUNTDIR/nfs_client1 
        else
            /opt/qa/tools/performance/perf.sh $MOUNTDIR/client1
        fi
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
    for i in $(seq 1 $num_clients)
    do
        let "j += 1";
        if [ $mount_type == "fuse" ]; then
            umount $MOUNTDIR/client$j;
            if [ $? -ne 0 ]; then
		echo "unmounting $MOUNTDIR/client$j failed.";
	    fi
            umount $MOUNTDIR/client$j -l;
        else if [ $mount_type == "nfs" ]; then
            umount $MOUNTDIR/nfs_client$j;
            if [ $? -ne 0 ]; then
		echo "unmounting $MOUNTDIR/nfs_client$j failed";
	    fi
            umount $MOUNTDIR/nfs_client$j -l;
        else if [ $mount_type == "both" ]; then
            umount $MOUNTDIR/client$j;
	    if [ $? -ne 0 ]; then
		echo "unmounting $MOUNTDIR/client$j failed";
	    fi
            umount MOUNTDIR/client$j -l;
            umount $MOUNTDIR/nfs_client$j;
            if [ $? -ne 0 ]; then
		echo "unmounting $MOUNTDIR/nfs_client$j failed";
	    fi
            umount $MOUNTDIR/nfs_client -l;
	fi
	fi
	fi
    done

    gluster --mode=script volume stop vol;
    if [ $? -ne 0 ]; then
        echo "Error while stopping glusterfs server processes.";
        return 11;
    fi

    gluster --mode=script volume delete vol;
    if [ $? -ne  0 ]; then 
	echo "Error while deleting the server processes. Going ahead with umount";
	return 11;
    fi
}

function stop_glusterd ()
{
    pkill glusterd;
}

function cleanup()
{
    rm -rfv $EXPORTDIR/*;
    rm -rfv $MOUNTDIR/client*;
    rm -rfv $MOUNTDIR/nfs_client*
    rm -rfv /etc/glusterd;
}

function pre_run_cleanup ()
{
    stop_glusterd;
    cleanup;
}

function pre_run()
{
   #     update_git;
    #set -e;
    echo "Entered pre_run";
        prepare_dirs;
        set -e;
        install_glusterfs;
}

function send_results()
{
	if [ ! -d $LOGDIR ]
	then
		mkdir $LOGDIR;
	fi
        cd $LOGDIR;

	if [ ! -d $RESULTDIR ]
	then
		mkdir $RESULTDIR;
	else
		rm -rf $RESULTDIR/*;
	fi

	cp -r $DEFAULT_LOGDIR $LOGDIR;
	rm -rf $DEFAULT_LOGDIR/*.log;
	rm -rf $DEFAULT_LOGDIR/bricks/*;

	#cp $LOGDIR/* $RESULTDIR;
        cp /export/runlog.$translator $RESULTDIR;
#	mv /export/tests_failed $LOGDIR/tests_failed_$translator;
#	echo $translator >> $LOGDIR/tests_failed_$translator;
#	cat /tmp/posix >> $LOGDIR/tests_failed_$translator;
	cat /tmp/git_head* >> $LOGDIR/perf-numbers_$translator;
	cat /export/bonnie >> $LOGDIR/perf-numbers_$translator;
	cat /export/iozone >> $LOGDIR/perf-numbers_$translator;
	cp /export/bonnie $LOGDIR;
	cp /expot/iozone $LOGDIR;

	DATE=$(date +%F);
	ls $COREDIR/core* ;
	if [ $? -eq 0 ]; then
	    echo "core generated for $translator" >> $LOGDIR/perf-numbers_$translator;
	    #mv $COREDIR/core* $CORE_REPOSITORY/core*_$translator_`date +%F`
	    for i in $(ls $COREDIR); do
		echo $i;
		if [ ! -d $CORE_REPOSITORY/$DATE ]; then
		    mkdir -p $CORE_REPOSITORY/$DATE;
		fi
		mv $COREDIR/$i $CORE_REPOSITORY/$DATE;
	    done
	fi
	
	cp $LOGDIR/* $RESULTDIR;
        tar cfj results_$translator.bz2 $RESULTDIR;
	cp $LOGDIR/perf-numbers_$translator $LOGDIR/tests_failed_$translator;
        #mutt -a results_$translator.bz2 -s "Performance sanity Results for `date +%F`" -i $LOGDIR/perf-numbers_$translator $EMAIL <.;

	###############IMP##############################
	#This part is needed if the iozone and bonnie results are to be uploaded in the dev server
#         cp /tmp/bonnie /tmp/bonnie_$translator_`date +%F`;
#         cp /tmp/iozone /tmp/iozone_$translator_`date +%F`;
#         scp /tmp/bonnie_`date +%F` raghavendrabhat@dev.gluster.com:/home/raghavendrabhat/public_html/test;
#         scp /tmp/iozone_`date +%F` raghavendrabhat@dev.gluster.com:/home/raghavendrabhat/public_html/test;
	##############IMP################################

	cp $LOGDIR/results_$translator.bz2 /tmp/logs_$translator.bz2
	scp /tmp/logs_$translator.bz2 raghavendrabhat@shell.gluster.com:/home/raghavendrabhat/result/
	scp $LOGDIR/tests_failed_$translator $EMAIL
	if [ $? -ne 0 ]; then
	    echo "sendimg mail failed" >/tmp/mail_sent;
	else
	    echo "sendimg mail successful" >/tmp/mail_sent;
	fi

        rm /export/bonnie /export/iozone;
	rm /tmp/logs_$translator.bz2;
}

function clean_results()
{
    directory=`date +%F`
#    mkdir /tmp/old/$directory -p;
#    mv $RESULTDIR/* /tmp/old/$directory
    rm -rf $RESULTDIR;
}

function syscallbench_plot()
{
    cp /tmp/`date +%F` $SYSCALLDIR
    cd $SYSCALLDIR 
    mv today yesterday
    ln -s `date +%F` today
    $TOOLDIR/syscallbench-plot today yesterday > $LOGDIR/plot.ps
}
    
function  check_and_kill ()
{
    pgrep glusterfs;
    if [ $? -eq 0 ]; then
	pkill glusterfs;
    fi

    pgrep glusterfsd;
    if [ $? -eq 0 ]; then
	pkill glusterfsd;
    fi

    pgrep glusterd;
    if [ $? -eq 0 ]; then 
	pkill glusterd;
    fi
}

function post_run()
{
        set +e;
        stop_glusterfs;
	check_and_kill;
        cleanup;
	syscallbench_plot;
        send_results;
	clean_results;
}

function main()
{
        echo "In main";
	#translator=$1
        trap "post_run" INT TERM EXIT;
	pre_run_cleanup;
        pre_run;
	start_glusterd;
        start_glusterfs;
        run_tests; 
        trap - INT TERM EXIT
        post_run;
}


#check for command line arg.
# if [ ! $# -eq 3 ]
# then
# echo "Usage: nightly.sh afr/dht/stripe <number of clients> <mount type>";
# exit;
# fi

_init "$@" && main "$@"

