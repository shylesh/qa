#!/bin/sh

echo "Executing $MMAP_DIR/mmapstress/mmapstress01.sh"
#cp $LTP_DIR/fs_perms/fs_perms.sh .
time $MMAP_DIR/mmapstress/mmapstress01 -p $MMAP_PROC -t $MMAP_TIME -f $MMAP_FILE_SIZE -r -o -l -m -d   2>>$LOG_FILE 1>>$LOG_FILE

if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
else
    echo "mmapstress01 failed"
    echo $PASS
fi

echo "Executing $MMAP_DIR/mmapstress/mmapstress02"
time $MMAP_DIR/mmapstress/mmapstress02  2>>$LOG_FILE 1>>$LOG_FILE 

if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
else
    echo "mmapstress02 failed"
    echo $PASS
fi

echo "Executing $MMAP_DIR/mmapstress/mmapstress03"
time $MMAP_DIR/mmapstress/mmapstress03  2>>$LOG_FILE 1>>$LOG_FILE 

if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
else
    echo "mmapstress03 failed"
    echo $PASS
fi

echo "Executing $MMAP_DIR/mmapstress/mmapstress04"
echo "Creating the file needed to be tested by mmapstress03"
touch mmap_file
time $MMAP_DIR/mmapstress/mmapstress04 mmap_file 0  2>>$LOG_FILE 1>>$LOG_FILE 

if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    rm mmap_file
    echo $PASS
else
    echo "mmapstress04 failed"
    rm mmap_file
    echo $PASS
fi

echo "Executing $MMAP_DIR/mmapstress/mmapstress05"
time $MMAP_DIR/mmapstress/mmapstress05  2>>$LOG_FILE 1>>$LOG_FILE 

if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
else
    echo "mmapstress05 failed"
    echo $PASS
fi

echo "Executing $MMAP_DIR/mmapstress/mmapstress06"
time $MMAP_DIR/mmapstress/mmapstress06 $MMAP_SLEEP_TIME  2>>$LOG_FILE 1>>$LOG_FILE 
if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
else
    echo "mmapstress06 failed"
    echo $PASS
fi

#not working below
echo "Executing $MMAP_DIR/mmapstress/mmapstress02"
time $MMAP_DIR/mmapstress/mmapstress02  2>>$LOG_FILE 1>>$LOG_FILE 

if [ $? -eq 0 ]; then
    let PASS=$PASS+1
    echo $PASS
else
    echo "mmapstress02 failed"
    echo $PASS
fi