#!/bin/bash

ulimit -c unlimited
#set -x
#set -u
export PATH=$PATH:/opt/qa/tools:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin
echo $PATH;

function _init()
{

arch=$(uname);
toprofile="toprofile"
    DEFAULT_LOGDIR="/usr/local/var/log/glusterfs";
    WORKSPACE_DIR="/gluster/glusterfs";
    ARCHIVEDIR="/archives/`date +%F`";
    CWDIR=`dirname $0`;
    DATE=`date +%F`;
    WORKDIR="/tmp/nightly";
    BUILDDIR="$WORKSPACE_DIR/build";
    
    LOGDIR="$WORKDIR/logs_$toprofile/`date +%F`";
    RESULTDIR="/tmp/nightly-results";
    COREDIR="$WORKDIR/$toprofile";
    CORE_REPOSITORY="/opt/cores";

    if [ "$arch" == "Linux" ]; then
        echo "$COREDIR/core" > /proc/sys/kernel/core_pattern;
	echo "1" > /proc/sys/kernel/core_uses_pid;
    fi

    echo "inited all the variables";
}


function prepare_dirs()
{

	if [ ! -d $RESULTDIR ];then
		mkdir -p $RESULTDIR;
	fi

	if [ ! -d $ARCHIVEDIR ];then
		mkdir -p $ARCHIVEDIR;
	fi

    if [ ! -d $LOGDIR ]; then
        mkdir -p $LOGDIR;
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
    git pull;

    ./autogen.sh;
    if [ ! -d $BUILDDIR ]
    then
        mkdir $BUILDDIR;
    fi
    cd $BUILDDIR;
    
    if [ "$arch" == "Linux" ]; then
        export CFLAGS="-g -O0 -DDEBUG";
        ../configure CFLAGS="-g -O0 -DDEBUG"  --quiet;
        make -j 32>/dev/null;
	echo "make done, Installing...";
        make install -j 32>/dev/null;
	make clean && make distclean;
    fi
}

function start_glusterd ()
{
    glusterd -LDEBUG
    if [ $? -ne 0 ]; then
        echo "glusterd could not be started. Returning"
        return 11;
    else
        echo "glusterd started successfully"
        return 0;
    fi
}



function stop_glusterd ()
{
    pkill glusterd;
}

function cleanup()
{
    rm -rfv /etc/glusterd;
    rm -rfv $DEFAULT_LOGDIR/*;
    rm -rfv $WORKDIR;
}

function pre_run_cleanup ()
{
    stop_glusterd;
    cleanup;
}

function pre_run()
{
    echo "Entered pre_run";
        prepare_dirs;
        set -e;
        install_glusterfs;
    echo "Exiting pre_run";
}

function save_and_send_results_and_logs()
{

#Arching Result and Logs

	egrep "PASS|FAIL|KEY" $RESULTDIR/temp.result >$RESULTDIR/top_profile.result
	cp -r $DEFAULT_LOGDIR/* $LOGDIR/;
	cp -r $LOGDIR $ARCHIVEDIR;
	cp $RESULTDIR/temp.result $ARCHIVEDIR ;
	cp $RESULTDIR/top_profile.result $ARCHIVEDIR ;

#Send the results to vishwanath@shell.gluster.com

	ssh vishwanath@shell.gluster.com "rm -f ~/top-profile_sanity/*" #Remove this ugly hack ASAP. inotify programme should be taking care of this.

	scp $RESULTDIR/top_profile.result vishwanath@shell.gluster.com:~/top-profile_sanity/
	scp $RESULTDIR/temp.result vishwanath@shell.gluster.com:~/top-profile_sanity/results_details.txt
}

function clean_results()
{
    directory=`date +%F`
    rm -rf $RESULTDIR;
}


function  check_and_kill ()
{

	pgrep gluster | xargs kill -9

}

function post_run()
{
        set +e;
	check_and_kill;
    	save_and_send_results_and_logs;
        cleanup;
	clean_results;
}

function main()
{
        echo "In main";
        trap "post_run" INT TERM EXIT;
	pre_run_cleanup;
        pre_run;
	start_glusterd;
	$CWDIR/top_profile.sh 192.168.1.222 192.168.1.222 >$RESULTDIR/temp.result 
        trap - INT TERM EXIT
        post_run;
}

_init "$@" && main "$@"

