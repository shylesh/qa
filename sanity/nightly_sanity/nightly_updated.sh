#!/bin/bash

ulimit -c unlimited
set -x
set -u
export PATH=$PATH:/opt/qa/tools:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin
echo $PATH;
#/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

function _init()
{
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
#       WORKSPACE_DIR="/opt/users/nightly_sanity/glusterfs.git";
#     else
#       if [ $mount_type == "nfs" ]; then
#       WORKSPACE_DIR="/opt/users/nfs_sanity/glusterfs.git";
#       else
#           echo "Unknown mount type $mount_type";
#           exit 22;
#       fi
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
    LOGREPO="/export/qalogs/sanity_logs/nightly_sanity";

    if [ "$arch" == "Linux" ]; then
        echo "$COREDIR/core" > /proc/sys/kernel/core_pattern;
        echo "1" > /proc/sys/kernel/core_uses_pid;
    fi

    #EMAIL="dl-qa@gluster.com"
#    EMAIL="raghavendrabhat@shell.gluster.com:/home/raghavendrabhat/nightly_sanity/";
#    EMAIL="raghavendrabhat@gluster.com";
    BINDIR="/opt/glusterfs/nightly";
    TOOLDIR="/opt/qa/tools/tools.git/syscallbench";
    echo "inited all the variables";
}

# WORKSPACE_DIR="/home/gluster/laks/new/glusterfs/"
# WORKDIR="/mnt/nightly"
# SPECDIR="/opt/users/vijay/nightly"
# BUILDDIR="$WORKSPACE_DIR/build"

# LOGDIR="$WORKDIR/logs/`date +%F`"
# EXPORTDIR=$WORKDIR/data
# MOUNTDIR=$WORKDIR/mount
# RESULTDIR=/tmp/nightly-results

# EMAIL="lakshmipathi@gluster.com"
# BINDIR="/home/gluster/laks/new/glusterfs/build/build"


# function update_git ()
# {
#         cd $WORKSPACE_DIR
#       echo "$WORKSPACE_DIR in there"
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
        mkdir -p $LOGDIR/old_dump/;
        mkdir -p $LOGDIR/new_dump/;
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
        export CFLAGS="-g3 -DDEBUG -lgcov --coverage";
        ../configure CFLAGS="-g3 -DDEBUG -lgcov --coverage" --enable-fusermount;
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
        gluster --mode=script volume create vol $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "afr" ]; then
        echo "Creating the replicate volume"
        gluster --mode=script volume create vol replica 2 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "stripe" ]; then
        echo "Creating the stripe volume";
        gluster --mode=script volume create vol stripe 4 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "disrep" ]; then
        echo "Creating a distributed-replicate volume";
        gluster --mode=script volume create vol replica 2 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
        if [ $? -ne 0 ]; then
            echo "gluster volume create failed. Check glusterd log file";
            return 11;
        else
            return 0;
        fi
    fi

    if [ $vol_type == "dis-stripe" ]; then
        echo "Creating a distributed-stripe volume";
        gluster --mode=script volume create vol stripe 2 $(hostname):$EXPORTDIR/export1 $(hostname):$EXPORTDIR/export2 $(hostname):$EXPORTDIR/export3 $(hostname):$EXPORTDIR/export4;
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
        # echo "Setting brick log-level to debug";
        # gluster volume set vol diagnostics.brick-log-level debug;
        # if [ $? -ne 0 ]; then
        #     echo "Setting brick log level to debug failed. Going with normal log";
        # fi
        # echo "Setting client log-level to debug";
        # gluster volume set vol diagnostics.client-log-level debug;
        # if [ $? -ne  0 ]; then
        #     echo "Setting client log level to debug failed. Going with normal log";
        # fi
        return 0;
    fi
}

function mount_volume ()
{
    echo "Started the volume. Mounting it"
    if [ $mount_type == "fuse" ]; then
        modprobe fuse;
        if [ $? -ne  0 ]; then
            echo "cannot load fuse. Exiting";
            return 11;
        fi

        for i in $(seq 1 $num_clients)
        do
            #mount -t glusterfs $(hostname):vol $MOUNTDIR/client$i
        glusterfs --volfile-server=$(hostname) --volfile-id=vol $MOUNTDIR/client$i -p /tmp/client_pid$i;
        df -h; #to be removed
        done
    fi

    if [ $mount_type == "nfs" ]; then
        sleep 2;
        gluster volume info vol;
        sleep 2;
        #showmount -e | grep -i "vol";
        success=$?;
        if [ $success -ne 0 ]; then
            echo "NFS server has not been started. There may be some problem while starting the volume or kernel nfs server may be running.";
            return 11;
        fi
        for i in $(seq 1 $num_clients)
        do
            sleep 1;
            mount -t nfs -o nolock $(hostname):vol $MOUNTDIR/nfs_client$i
        done
    fi

    if [ $mount_type == "both" ]; then
        for i in $(seq 1 $num_clients)
        do

            modprobe fuse;
            if [ $? -ne 0 ]; then
                echo "cannot load fuse. Exiting";
                return 11;
            fi

            #mount -t glusterfs $(hostname):vol $MOUNTDIR/client$i
            glusterfs --volfile-server=$(hostname) --volfile-id=vol $MOUNTDIR/client$i -p /tmp/client_pid$i;
            sleep 2;
            gluster volume info vol;
            sleep 2;
            mount -t nfs -o nolock $(hostname):vol $MOUNTDIR/nfs_client$i
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
            /opt/qa/tools/system_light/run.sh -w $MOUNTDIR/nfs_client1 -t nfs -l /export/runlog.$translator
        fi

        if [ $mount_type == "fuse" ]; then
            echo "executing tests on a fuse mount point"
            /opt/qa/tools/system_light/run.sh -w $MOUNTDIR/client1 -l /export/runlog.$translator
        fi

        # if [ $mount_type == "nfs" ]; then
#           echo "executing tests on an nfs mount point"
#           /opt/qa/tools/system_light/run.sh -w $MOUNTDIR/nfs_client1 -t nfs -l /export/runlog.$translator;
#       fi

        x=$?;
        if [ !x ]
        then
                echo "Sanity Passed!";
        else
                echo "Sanity Failed. Please check your changes!";
        fi

        echo "Contents of mount point after all the tests" >> /export/runlog.$translator;
        if [ "$arch" == "SunOs" ] || [ "$mount_type" == "nfs" ]; then
            ls -laR $MOUNTDIR/nfs_client1 >> /export/runlog.$translator;
            echo "removing the mount point contents" >> /export/runlog.$translator;
            rm -rfv $MOUNTDIR/export/nfs_client1/*;
        fi

        if [ "$mount_type" == "fuse" ]; then
            ls -laR $MOUNTDIR/client1 >> /export/runlog.$translator;
            echo "removing the mount point contents" >> /export/runlog.$translator;
            rm -rfv $MOUNTDIR/export/client1/*;
        fi
        set -e;

}

function stop_glusterfs()
{

    #     This is a hack. Locktests process should not be running after the test is completed. Need to investigate it more. For time being just kill it forcefully so that there are no stale processes running even after the mount point is unmounted.

    pgrep locktests;
    if [ $? -eq 0 ]; then
        pkill locktests;
        if [ $? -ne 0 ]; then
            killall -KILL locktests;
        fi
    fi

    j=0;
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
            set +e;
            umount $MOUNTDIR/nfs_client$j;
            if [ $? -ne 0 ]; then
                echo "unmounting $MOUNTDIR/nfs_client$j failed";
            fi
            umount $MOUNTDIR/nfs_client$j -l;
            set -e;
        else if [ $mount_type == "both" ]; then
            set +e;
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
            set -e;
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

    set +e;
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
    prepare_gcov $WORKSPACE_DIR;

}

function prepare_gcov ()
{
    local dir;

    dir=$1;
    set +e;

    coverage_dir=$dir/build;

    if [ ! -d $coverage_dir/coverage ]; then
        mkdir $coverage_dir/coverage;
    fi

    # Reset all execution count details.
    lcov -d $dir --zerocounters;

    # Run lcov initially with zero code coverage and put it in a ".info" file.
    lcov -i -c -d $dir -o $coverage_dir/coverage/glusterfs-lcov.info;

    # Now the sanity tests can be run after which we again look back to gcov.
    set -e;
}

function post_run_gcov ()
{
    local dir;

    dir=$1;

    coverage_dir=$dir/build;
    # Capture the actual code coverage.
    lcov -c -d $dir -o $coverage_dir/coverage/glusterfs-lcov.info;

    # Remove the line with "<gluster-repo>/libglusterfs/src/<stdout>"
    # from ".info" file. For some reason genhtml fails otherwise.

    sed -i.bak '/stdout/d' $coverage_dir/coverage/glusterfs-lcov.info;

    # Generate the html page for code coverage details using genhtml.
    genhtml -o $coverage_dir/coverage/ $coverage_dir/coverage/glusterfs-lcov.info;
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

        #cp -r $LOGDIR/* $RESULTDIR;
        cp /export/runlog.$translator $RESULTDIR;
        mv /export/tests_failed $LOGDIR/tests_failed_$translator;
        echo $translator >> $LOGDIR/tests_failed_$translator;
        echo $mount_type >> $LOGDIR/tests_failed_$translator;
        cat /tmp/posix | grep FAILED >> $LOGDIR/tests_failed_$translator;
        cat /tmp/git_head* >> $LOGDIR/tests_failed_$translator;
        #cat /tmp/bonnie >> $LOGDIR/tests_failed_$translator;
        #cat /tmp/iozone >> $LOGDIR/tests_failed_$translator;
        cat /export/$(date +%F) >>$LOGDIR/tests_failed_$translator;
        mv /export/$(date +%F) $LOGDIR;

        DATE=$(date +%F);
        found_gluster_core=0;
        ls $COREDIR/core* ;
        if [ $? -eq 0 ]; then
            if [ ! -d $CORE_REPOSITORY/$DATE ]; then
                mkdir $CORE_REPOSITORY/$DATE;
            fi

            for i in $(ls $COREDIR)
            do
                file $COREDIR/$i | grep gluster;
                if [ $? -eq 0 ]; then
                    found_gluster_core=1;
                    echo $i;
                    mv $COREDIR/$i $CORE_REPOSITORY/$DATE/$i;
                fi
            done

            if [ $found_gluster_core -eq 1 ]; then
                echo "core generated for $translator" >> $LOGDIR/tests_failed_$translator;
            else
                rm -rf $COREDIR/core*;
            fi
            #mv $COREDIR/core* $CORE_REPOSITORY/core*_$translator_`date +%F`
        fi

        echo "Critical and error logs for client, nfs and glusterd" >> $LOGDIR/logs_failed_$translator;
        for i in $(find $DEFAULT_LOGDIR -type f -iname "*.log")
        do
            echo "error and critical logs in $(basename $i)" >> $LOGDIR/logs_failed_$translator;
            grep "\ E\ " $i >> $LOGDIR/logs_failed_$translator;
            grep "\ C\ " $i >> $LOGDIR/logs_failed_$translator;
        done

        echo "Critical and error logs for server processes" >> $LOGDIR/logs_failed_$translator;
        for i in $(find $DEFAULT_LOGDIR/bricks -type f -iname "*.log")
        do
            echo "error and critical logs in $(basename $i)" >> $LOGDIR/logs_failed_$translator;
            grep "\ E\ " $i >> $LOGDIR/logs_failed_$translator;
            grep "\ C\ " $i >> $LOGDIR/logs_failed_$translator;
        done

        rm -rf $DEFAULT_LOGDIR/*.log;
        rm -rf $DEFAULT_LOGDIR/bricks/*;

        cp -r $LOGDIR/* $RESULTDIR;
        cp -r $BUILDDIR/coverage/ $RESULTDIR;

        tar cjf results_$translator.bz2 $RESULTDIR;

        ############################### copying the patches applied today ##################################

        cp -r /tmp/patches/ $LOGDIR;

        ####################################################################################################

        # git push log files
        echo "Pushing logs to qalogs git repo: "
        mkdir -p $LOGREPO/`date +%F`/$translator/
        cp $LOGDIR/results_$translator.bz2 $LOGREPO/`date +%F`/$translator/;
        cd /export/qalogs && git pull && git add . && git commit -a -m "log for `date +%F`" && git push;
        if [ $? -ne 0 ]; then
            echo "Commit failed. Recommit bz2 log manually." > /tmp/git_log_commit;
        else
            echo "Commit successful." > /tmp/git_log_commit;
        fi
        cd $LOGDIR;

#	echo "Sending results";
#	sleep 2;
#        mutt -a results_$translator.bz2 -s "Sanity Results for `date +%F`" -i $LOGDIR/tests_failed_$translator $EMAIL <.;

        ###############IMP##############################
        #This part is needed if the iozone and bonnie results are to be uploaded in the dev server
#         cp /tmp/bonnie /tmp/bonnie_$translator_`date +%F`;
#         cp /tmp/iozone /tmp/iozone_$translator_`date +%F`;
#         scp /tmp/bonnie_`date +%F` raghavendrabhat@dev.gluster.com:/home/raghavendrabhat/public_html/test;
#         scp /tmp/iozone_`date +%F` raghavendrabhat@dev.gluster.com:/home/raghavendrabhat/public_html/test;
        ##############IMP################################

#        rm /export/bonnie /export/iozone;
        rm /tmp/posix;

        mkdir /tmp/gcov_logs;
        cp -r $BUILDDIR/coverage/ /tmp/gcov_logs;
        cp $LOGDIR/logs_failed_$translator /tmp/gcov_logs;

        cd /tmp/;
        tar cjf logs_failed_$translator.bz2 gcov_logs;
        cd -;

        scp /tmp/logs_failed_$translator.bz2 $EMAIL/result/;
        scp $LOGDIR/tests_failed_$translator $EMAIL/nightly_sanity/;
        if [ $? -ne 0 ]; then
            echo "sending mail failed" > /tmp/mail_result;
        else
            echo "sending mail successful" >/tmp/mail_result;
        fi

        # remove the logs and the index file containing directory.
        rm -rf /tmp/gcov_logs /tmp/logs_failed_$translator.bz2;
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
        post_run_gcov $WORKSPACE_DIR;
        send_results;
        cleanup;
        syscallbench_plot;
        clean_results;
}

function take_statedump ()
{
    local dir;

    echo 3 > /proc/sys/vm/drop_caches;
    sleep 2;

    dir=$1;
    for i in $(ls /etc/glusterd/vols/vol/run)
    do
      BRICK_PID=$(cat /etc/glusterd/vols/vol/run/$i);
      kill -USR1 $BRICK_PID;
      sleep 1;
      mv /tmp/*.$BRICK_PID.dump $dir;
    done

    for j in $(seq 1 $num_clients)
    do
      CLIENT_PID=$(cat /tmp/client_pid$j);
      kill -USR1 $CLIENT_PID;
      sleep 1;
      mv /tmp/*.$CLIENT_PID.dump $dir;
    done
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
        take_statedump $LOGDIR/old_dump/;
        run_tests;
        take_statedump $LOGDIR/new_dump/;
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
