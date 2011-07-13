#compilebench

mkdir -p /mnt/export/gluster/cloud/mnt/1014/46/`hostname`/Tc16

cd /opt/qa/nfstesting/compilebench/build/compilebench-0.6/

( /opt/qa/nfstesting/compilebench/build/compilebench-0.6/compilebench -­D /mnt/export/gluster/cloud/mnt/1014/46/`hostname`/Tc16 ­-i 10 -­r 1000 --makej >& /opt/qa/nfstesting/compilebenlog/`hostname`_`date +%h%d%T`.compilebench.log ) &



#tc11

mkdir -p /mnt/export/gluster/cloud/mnt/1014/46/`hostname`/Tc11

cp /opt/qa/nfstesting/Tc12/linux-2.6.33.2.tar.bz2 /mnt/export/gluster/cloud/mnt/1014/46/`hostname`/Tc11



cd /mnt/export/gluster/cloud/mnt/1014/46/`hostname`/Tc11



( for i in {1..100};

do

 rm -rf linux-2.6.33.2

 bzip2 -d linux-2.6.33.2.tar.bz2

 tar­-xvf linux-2.6.33.2.tar

 cd linux-2.6.33.2

 make defconfig 

 make 

 make distclean 

done

) &

echo "~~~~~~>Done.started nfstestcase-11 in bkground"  >> /opt/qa/nfstesting/Tools_Status_`hostname`.log



