#!/bin/bash
set -xe
#This script will perform following actions
# a) create will tar file from developer's current working directory using aws ssh key from $KEY directory.
# b) transfer the tar file to remote machine (REMOTE_SYS) for testing.
# c) and archive the tar file.

#
#directories
BASENAME=/sanity/test
TARBALL_DIR=$BASENAME/tarball

#tar file name 
TARFILE=glusterfs.tar
BACKUP_DIR=$BASENAME/archive

#logfile
LOG_FILE=$BASENAME/sanity.log

#glusterfs test machine
REMOTE_USER=root
REMOTE_SYS="192.168.1.85" #dev-sanity #ec2-174-129-181-3.compute-1.amazonaws.com
REMOTE_DIR=/sanity/test/incoming
REMOTE_SYS1="10.1.12.191" 
REMOTE_SYS2="10.1.12.192" 
#aws key file path
KEY=~

#transfer the file.
function file_transfer(){
echo "coping file $TARBALL_DIR/$TARFILE  to remote system $REMOTE_USER@$REMOTE_SYS" >> $LOG_FILE 2>&1
TARFILE=`ls -tr $TARBALL_DIR/ | head -1`
echo "Got the file $TARFILE" >> $LOG_FILE 2>&1

#while copying to remote directory with name of translator.
echo "doing scp $TARBALL_DIR/$TARFILE $REMOTE_USER@$REMOTE_SYS:/$REMOTE_DIR/$translator$usr`hostname` .tar"  >> $LOG_FILE 2>&1
remote_file=$translator"_"$usr"_"`hostname`.tar
#scp -i $KEY/gluster.pem 

if [ $translator == "afr" ];then
scp $TARBALL_DIR/$TARFILE $REMOTE_USER@$REMOTE_SYS:/$REMOTE_DIR/$remote_file
fi
if [ $translator == "dht" ];then
scp $TARBALL_DIR/$TARFILE $REMOTE_USER@$REMOTE_SYS1:/$REMOTE_DIR/$remote_file
fi
if [ $translator == "stripe" ];then
scp $TARBALL_DIR/$TARFILE $REMOTE_USER@$REMOTE_SYS2:/$REMOTE_DIR/$remote_file
fi

echo "archive the tar file" >> $LOG_FILE 2>&1
mkdir -vp $BACKUP_DIR/`date +%m_%d_%y` >> $LOG_FILE 2>&1
mv  -v $TARBALL_DIR/$TARFILE $BACKUP_DIR/`date +%m_%d`/$remote_file.`date +%T`.gz >> $LOG_FILE 2>&1

}

function usage_help(){
		echo "usage: sanity_check.sh <check-value> <gluster-mail-id>"
		echo "<check-value> can be one of following three values ,afr or dht or stripe"
		echo "example : sanity_check.sh afr user@gluster.com"
		exit;
}

# Main part
translator=$1
#get user name
usr=`echo $2 | awk '{split($0,array,"@")} END{print array[1]}'`
echo $usr


if [ ! $# -eq 2 ]
	then
	usage_help
	fi
[ $translator != afr ] && [ $translator != dht ] && [ $translator != stripe ] && echo "Invalid option." && usage_help

#if required directories not exists creat them.
mkdir -p $TARBALL_DIR
mkdir -p $BACKUP_DIR
echo "Creating tar file .."
git archive --format=tar HEAD   > $TARBALL_DIR/$TARFILE
echo "done"
#transfer the tar file.
echo "transferring tar file.."
file_transfer

if [ $? -eq 0 ]
	then 
	echo "File transferred successfully,logs will be sent to $2"
	fi



