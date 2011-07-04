#!/bin/bash
set -x

#Note : This script will be invoked from inotify.c program as soon as any new files created under /sanity/test/incoming directory.
#also note , incoming tar file will be in format  <translatorName_glusterUsername_developerHostname.tar> For ex:afr_lakshmipathi_entropy.tar 

# This script will pick up file from /sanity/test/incoming directory and performs following tasks
# a) Check whether no process is running,if so then move the tar file from queue to build directory ,extract it and build.
#   If process already running or build directory is not empty or mount point already in use,sleep 60 seconds & and check again.
# b) then start  gluster and mount it on client mount point.
# c) finally perform QA test on mount point.
# d) mail the results 





#directories
BASENAME=/sanity/test	
INCOMING_DIR=$BASENAME/incoming #where new tar will be scp'ed from remote machines.
BUILD_DIR=$BASENAME/build	#where glusterfs build is done. 
RESULTS_DIR=$BASENAME/results   # final QA test results will be available.
QUEUE_DIR=$BASENAME/queue	#tar files will be queued here first,before moving to build dir.
MOUNT_PT=/export/sanity		#sanity test mount point
#RESULTS_DIR=$MOUNT_PT/results


#Standard volume files will be available under VOL_DIR
VOL_DIR=$BASENAME/spec
# for afr
AFR_CLIENT_VOL=$VOL_DIR/afr_client.vol
AFR_SERVER_VOL=$VOL_DIR/afr_server.vol
#for stripe
STRIPE_CLIENT_VOL=$VOL_DIR/stripe_client.vol
STRIPE_SERVER_VOL=$VOL_DIR/stripe_server.vol
#for dht
DHT_CLIENT_VOL=$VOL_DIR/dht_client.vol
DHT_SERVER_VOL=$VOL_DIR/dht_server.vol

#glusterfs installation path
INSTALL_DIR=$BASENAME/install
TRASH_DIR=$BASENAME/trash

#sanity script logfile
LOG_FILE=$BASENAME/sanity.log

#qa tools path
QA_DIR=/opt/qa/tools/system_light
QA_TOOLS=/opt/qa/tools/system_light/run.sh


########################################### functions########################################### 



#move the tar file from INCOMING_DIR to QUEUE_DIR.
function mv_incoming_queue(){
echo "mv_incoming_queue:==>start" >> $LOG_FILE 2>&1

tarball=`ls -tr $INCOMING_DIR | head -1`
echo "mv_incoming_queue:Moving tar file from $INCOMING_DIR/$tarball to $QUEUE_DIR" >> $LOG_FILE 2>&1
if [ -f $tarball ]
then
    echo " $tarball file exist" >> $LOG_FILE 2>&1
else
    echo "file not found " >> $LOG_FILE 2>&1
fi

#cut tar part from transltor - so that it could be used for vol.name,log file and mount point.
translator_name=`echo $tarball | awk '{split($0,array,"_")} END{print array[1]}'`

#before moving to tar to queue , check whether any file with same name exists - if so ,then add inode that file.
if [ -f $QUEUE_DIR/$tarball ]
then
    echo " $tarball file exist.move it queue after renaming it." >> $LOG_FILE 2>&1
	mv $INCOMING_DIR/$tarball $QUEUE_DIR/`echo $tarball | awk '{split($0,array,".")} END{print array[1]}'`.`ls -i $INCOMING_DIR/$tarball | cut -d' ' -f1`.tgz
else
mv $INCOMING_DIR/$tarball $QUEUE_DIR
fi

echo "mv_incoming_queue:==> exit " >> $LOG_FILE 2>&1
}




			
#move file from QUEUE_DIR to BUILD_DIR
function mv_queue_build(){
echo "mv_queue_build:==>start" >> $LOG_FILE 2>&1
echo "mv_queue_build:Moving tar file from  $QUEUE_DIR to build " >> $LOG_FILE 2>&1

tarball=`ls -tr $QUEUE_DIR | head -1`
if [ -f $1 ]
then
    echo " $tarball file exist" >> $LOG_FILE 2>&1
else
    echo "file not found " >> $LOG_FILE 2>&1
fi

echo "moving $QUEUE_DIR/$tarball to $BUILD_DIR/$translator_name" >> $LOG_FILE 2>&1
mv -v $QUEUE_DIR/$tarball  $BUILD_DIR/$translator_name >> $LOG_FILE 2>&1
echo "mv_queue_build:==> exit " >> $LOG_FILE 2>&1
}






#check whether tar can be moved from Queue to build - to start build process.
#So a) check mount point is free or not.b)glusterfs/d already running or not.c)Verify build directory ,ensure no other process started building.
function is_ready(){
echo "is_ready:==>start" >> $LOG_FILE 2>&1

#is glusterfs client already mounted,for specific translator?
echo "checking for $translator_name_client.vol"
cat /etc/mtab | grep $translator_name"_client.vol"
if [ $? -eq 0 ]
then
    echo " `date` : $translator_name Already  mounted" >> $LOG_FILE 2>&1
    echo " `date` : No free slot avail. for $translator_name" 
	sleep 60
	is_ready
else
    echo "not  mounted.proceed. " >> $LOG_FILE 2>&1 
    rm -rf $BASENAME/$translator_name"_mail.txt"
    touch $BASENAME/$translator_name"_mail.txt"

fi


#is glusterfs and glusterfsd aready running for the given translator?
for file in `pgrep glusterfs`
do
grep $translator_name"_client.vol" /proc/$file/cmdline 
if [ $? -eq 0 ]
	then 
	echo "$translator_name client runnning with pid $file"
	sleep 60
	is_ready
	fi
grep $translator_name"_server.vol" /proc/$file/cmdline 
if [ $? -eq 0 ]
	then 
	echo "$translator_name server runnning with pid $file"
	sleep 60
	is_ready
	fi
done

#glusterfs not running and not mounted but it's building.
if [ "$(ls -A $BUILD_DIR/$translator_name)" ]; then
     echo "$BUILD_DIR/$translator_name is not Empty - Some other process is building glusterfs" >> $LOG_FILE 2>&1
	sleep 60
	is_ready
else
    echo "$BUILD_DIR/$translator_name is Empty. Proceed." >> $LOG_FILE 2>&1
fi
echo "is_ready:==> exit " >> $LOG_FILE 2>&1
}




#Build glusterfs from src
function build_glusterfs(){
echo " build_glusterfs:==>start" >> $LOG_FILE 2>&1
echo " moving to $BUILD_DIR/$translator_name and extract $tarball" >> $LOG_FILE 2>&1
cd $BUILD_DIR/$translator_name && tar -xvf $tarball 
#buildflag - status of build
buildflag='y'
#run autogen.sh
./autogen.sh
echo "perform cmm" >> $LOG_FILE 2>&1
./configure --prefix $INSTALL_DIR/$translator_name
make && make install
if [ $? -eq 0 ]
then
    echo "build successful." >> $LOG_FILE 2>&1
else
    echo "build not successful. " >> $LOG_FILE 2>&1
     buildflag='n'
fi
echo " build_glusterfs:==> exit " >> $LOG_FILE 2>&1
}





#make sure standard volume files already present on the system.-check for missing volume files.
function check_vol_files(){
MISSING_FILES='n'
 [ ! -f   $AFR_CLIENT_VOL ] && 	echo "$AFR_CLIENT_VOL not found " && MISSING_FILES='y'
 [ ! -f $AFR_SERVER_VOL ] &&  echo "$AFR_SERVER_VOL not found" && MISSING_FILES='y'
 [ ! -f $STRIPE_CLIENT_VOL  ] &&  echo "$STRIPE_CLIENT_VOL not found" && MISSING_FILES='y'
 [ ! -f $STRIPE_SERVER_VOL  ] &&   echo "$STRIPE_SERVER_VOL not found" && MISSING_FILES='y'
 [ ! -f $DHT_CLIENT_VOL  ] &&   echo "$DHT_CLIENT_VOL not found" && MISSING_FILES='y'
 [ ! -f $DHT_SERVER_VOL  ] &&  echo "$DHT_SERVER_VOL not found" && MISSING_FILES='y'

if [ $MISSING_FILES == 'n' ]
	then 
		echo "volumes files found" >> $LOG_FILE 2>&1
	else
		echo "Missing Volume files" >> $LOG_FILE 2>&1
fi

}



#start glusterfs server.
function start_glusterfsd(){
echo " start_glusterfsd:==>start" >> $LOG_FILE 2>&1
#Log and volume files  named after specified translator like stripe_client.vol or afr_client.vol
server_vol=$translator_name"_server.vol"
server_log=$translator_name"_server.log"
start_server='y'

echo "Starting glusterfs server" >> $LOG_FILE 2>&1
echo "Running command:$INSTALL_DIR/$translator_name/sbin/glusterfsd -f $VOL_DIR/$server_vol -l $RESULTS_DIR/$server_log -L DEBUG" >> $LOG_FILE 2>&1
$INSTALL_DIR/$translator_name/sbin/glusterfsd -f $VOL_DIR/$server_vol -l $RESULTS_DIR/$server_log -L DEBUG &

if [ $? -eq 0 ]; then
echo "server started successfully." >> $BASENAME/$translator_name"_mail.txt"
else
echo "Unable to start glusterfsd.See log file  $RESULTS_DIR/$server_log for more details" >> $BASENAME/$translator_name"_mail.txt"
start_server='n'
fi
echo " start_glusterfsd:==> exit " >> $LOG_FILE 2>&1
}
#creat and start glusterfsd 
function creat_start_glusterfsd(){
pgrep glusterd
if [ $? -eq 1 ];then
$INSTALL_DIR/$translator_name/sbin/glusterd
fi

#re-create backend newly
rm -rf /export/sanity/afr_export*

mkdir -p /export/sanity/afr_export
mkdir -p /export/sanity/afr_export1

#creat volume
$INSTALL_DIR/$translator_name/sbin/gluster volume create $translator_name replica 2 `hostname`:/export/sanity/afr_export `hostname`:/export/sanity/afr_export1
#start volume
$INSTALL_DIR/$translator_name/sbin/gluster volume start $translator_name
if [ $? -eq 0 ]; then
echo "Following gluster volume started successfully." >> $BASENAME/$translator_name"_mail.txt"
$INSTALL_DIR/$translator_name/sbin/gluster volume info >> $BASENAME/$translator_name"_mail.txt"
echo "----------------------------------------------";
fi
}


#start glusterfs client.
function start_glusterfs(){
echo " start_glusterfs:==>start" >> $LOG_FILE 2>&1
echo "Trying to mount glusterfs on $MOUNT_PT/$translator_name " >> $LOG_FILE 2>&1

#client volume file name and log file name
client_vol=$translator_name"_client.vol"
client_log=$translator_name"_client.log"
start_client='y'

echo "Running command:$INSTALL_DIR/$translator_name/sbin/glusterfs -f $VOL_DIR/$client_vol $MOUNT_PT/$translator_name -l $RESULTS_DIR/$client_log -L DEBUG" >> $LOG_FILE 2>&1
$INSTALL_DIR/$translator_name/sbin/glusterfs -f $VOL_DIR/$client_vol $MOUNT_PT/$translator_name -l $RESULTS_DIR/$client_log -L DEBUG 

if [ $? -eq 0 ]; then
echo "glusterfs client started" >> $BASENAME/$translator_name"_mail.txt"
else
echo "Unable to mount glusterfs.See log file  for more details" >> $BASENAME/$translator_name"_mail.txt"
start_client='n'
fi
echo " start_glusterfs:==> exit " >> $LOG_FILE 2>&1
}
#mount gluster volume
function mount_glusterfs(){
mount -t glusterfs `hostname`:$translator_name $MOUNT_PT/$translator_name
if [ $? -eq 0 ];then
echo "gluster volume mounted successfully." >> $BASENAME/$translator_name"_mail.txt"
df >> $BASENAME/$translator_name"_mail.txt"
echo "-----------------------------------";
fi
}

function umount_glusterfs(){
umount -l $MOUNT_PT/$translator_name
}

function stop_glusterd(){
$INSTALL_DIR/$translator_name/sbin/gluster --mode=script volume  stop $translator_name
$INSTALL_DIR/$translator_name/sbin/gluster --mode=script volume  delete $translator_name
/etc/init.d/glusterd stop

#cleanup build dirs
rm -f $BUILD_DIR/$translator_name/.gitignore 
mv -vf $BUILD_DIR/$translator_name/*  $TRASH_DIR # >> $LOG_FILE 2>&1
rm -rf $TRASH_DIR/*
}



#perform QA test.
function start_tests() {
echo " start_tests:==>start" >> $LOG_FILE 2>&1

    echo "starting QA test"  >> $LOG_FILE 2>&1
    cd $QA_DIR
    $QA_TOOLS -w $MOUNT_PT/$translator_name  -l $RESULTS_DIR/$translator_name"QA.log"
    echo "QA test: completed" >> $BASENAME/$translator_name"_mail.txt"

echo " start_tests:==> exit " >> $LOG_FILE 2>&1
}



#save logs and sent a mail.
function cleanup(){
echo "cleanup ==> start " >> $LOG_FILE 2>&1
#stop glusterfs and glusterfsd 
for file in `pgrep glusterfs`
do
grep $translator_name"_client.vol" /proc/$file/cmdline 
if [ $? -eq 0 ]
	then 
	kill $file
	fi
grep $translator_name"_server.vol" /proc/$file/cmdline 
if [ $? -eq 0 ]
	then 
	kill $file
	fi
done

#save results
echo "Moving glusterfs log files " >> $LOG_FILE 2>&1
trans_user_sys=`echo $tarball | awk '{split($0,array,".")} END{print array[1]}'`

#logs=$RESULTS_DIR/$translator_name/$trans_user_sys/`date +%m_%d_%y_%T`
mkdir -p $RESULTS_DIR/$translator_name/$trans_user_sys
cd $RESULTS_DIR/$translator_name/$trans_user_sys
logs=`date +%m_%d_%y_%T`
mkdir -vp $logs >> $LOG_FILE 2>&1

mv  -v $RESULTS_DIR/$server_log   $logs/ >> $LOG_FILE 2>&1
mv  -v $RESULTS_DIR/$client_log  $logs/ >> $LOG_FILE 2>&1

echo "Moving QA test log file "  >> $LOG_FILE 2>&1
mv  -v $RESULTS_DIR/$translator_name"QA.log"  $logs >> $LOG_FILE 2>&1

#create tar file of logs
echo "creating tar file tar cfz $trans_user_sys".tgz" $logs " >> $LOG_FILE 2>&1 
tar cfz $trans_user_sys".tgz" $logs

#attach the log files and sent to developer.
#get from address
usr=`echo $trans_user_sys | cut -d'_' -f2`
sys=`echo $trans_user_sys | cut -d'_' -f3`
echo "See attached log files for more details " >> $BASENAME/$translator_name"_mail.txt"
#mutt -s "Developer Sanity Test" -a $trans_user_sys".tgz" "$usr@gluster.com" < $BASENAME/$translator_name"_mail.txt"
mail -s "dev sanity test results"  -a $trans_user_sys".tgz" "$usr@gluster.com" < $BASENAME/$translator_name"_mail.txt"
rm -f $BUILD_DIR/$translator_name/.gitignore 
mv -vf $BUILD_DIR/$translator_name/*  $TRASH_DIR >> $LOG_FILE 2>&1

echo "Cleanup installed binaries" >> $LOG_FILE 2>&1
mv  -v $INSTALL_DIR/$translator_name/* $TRASH_DIR >> $LOG_FILE 2>&1
mv $BASENAME/$translator_name"_mail.txt" $TRASH_DIR
rm  -r $TRASH_DIR/* >> $LOG_FILE 2>&1

echo "cleanup ==> exit " >> $LOG_FILE 2>&1
}

function mail_status(){
#mail -s "dev sanity test results"  -a $trans_user_sys".tgz" "$usr@gluster.com" < $BASENAME/$translator_name"_mail.txt"
#save results
echo "Moving glusterfs log files " >> $LOG_FILE 2>&1
trans_user_sys=`echo $tarball | awk '{split($0,array,".")} END{print array[1]}'`

#logs=$RESULTS_DIR/$translator_name/$trans_user_sys/`date +%m_%d_%y_%T`
mkdir -p $RESULTS_DIR/$translator_name/$trans_user_sys
cd $RESULTS_DIR/$translator_name/$trans_user_sys
logs=`date +%m_%d_%y_%T`
mkdir -vp $logs >> $LOG_FILE 2>&1

#mv  -v $RESULTS_DIR/$server_log   $logs/ >> $LOG_FILE 2>&1
#mv  -v $RESULTS_DIR/$client_log  $logs/ >> $LOG_FILE 2>&1

echo "Moving QA test log file "  >> $LOG_FILE 2>&1
mv  -v $RESULTS_DIR/$translator_name"QA.log"  $logs >> $LOG_FILE 2>&1

#create tar file of logs
echo "creating tar file tar cfz $trans_user_sys".tgz" $logs " >> $LOG_FILE 2>&1 
tar cfz $trans_user_sys".tgz" $logs

#attach the log files and sent to developer.
#get from address
usr=`echo $trans_user_sys | cut -d'_' -f2`
sys=`echo $trans_user_sys | cut -d'_' -f3`
echo "See attached log files for more details " >> $BASENAME/$translator_name"_mail.txt"
#mutt -s "Developer Sanity Test" -a $trans_user_sys".tgz" "$usr@gluster.com" < $BASENAME/$translator_name"_mail.txt"
cat  /sanity/test/results/tests_failed >> $BASENAME/$translator_name"_mail.txt"
rm -rf /sanity/test/results/tests_failed
mail -s "dev sanity test results"  -a $trans_user_sys".tgz"  "$usr@gluster.com" < $BASENAME/$translator_name"_mail.txt"
}

########################################### MAIN part###########################################

echo "###########sanity_test.sh log################################" >> $LOG_FILE 2>&1

date>>$LOG_FILE
echo "############" >> $LOG_FILE 2>&1


#move the tar file
#echo "checking volume files" >> $LOG_FILE 2>&1
#check_vol_files
#echo "done." >> $LOG_FILE 2>&1


#move $INCOMING tar file to $QUEUE directory.
echo "moving tar file to $QUEUE_DIR directory" >> $LOG_FILE 2>&1
mv_incoming_queue	
echo "done." >> $LOG_FILE 2>&1

#check for status
is_ready


#move from $QUEUE to $BUILD if it is free.
echo "Moving to build.." >> $LOG_FILE 2>&1
mv_queue_build

echo "Start building.." >> $LOG_FILE 2>&1
build_glusterfs
echo "done." >> $LOG_FILE 2>&1
if [ $buildflag == 'n' ]
	then
	echo "build process  : FAILED" >> $BASENAME/$translator_name"_mail.txt"
	else
	echo  "build process : PASSED" >> $BASENAME/$translator_name"_mail.txt"
	#start_glusterfsd # starting server
	creat_start_glusterfsd
#	if [ $start_server == 'y' ]
#	then
#	start_glusterfs  # starting client
#	fi
	#qa testing
	mount_glusterfs;sleep 10;
#	if [ $start_client == 'y' ]
#	then
	start_tests  # start testing 
#	fi

fi
#clean up build dir
#cleanup
umount_glusterfs
stop_glusterd
mail_status
###########################################EOF###########################################

