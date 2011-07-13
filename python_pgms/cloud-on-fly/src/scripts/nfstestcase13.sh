#EDIT NFSSERVER MANUALLY
cd CLOUD_MNT_PT

mkdir `hostname`

for i in {1..50};
do
if [ -d $i ];
then echo " yes";
else mkdir -p $i;
break;
fi;
done
cd CLOUD_MNT_PT/`hostname`/$i

mkdir -p /opt/qa/nfstesting/tc13
cd /opt/qa/nfstesting/tc13
if [ ! -f /opt/qa/nfstesting/tc13/linux-2.6.33.2.tar.bz2 ] 
then
wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
tar -xjf linux-2.6.33.2.tar.bz2
fi
mkdir -p CLOUD_MNT_PT/`hostname`/$i
cd /tmp
cp ­-R /opt/qa/nfstesting/tc9/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/$i
umount CLOUD_MNT_PT
( for k in $(seq 1 100);
do
mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
rsync -avz -ignore-times   CLOUD_MNT_PT/`hostname`/$i/linux-2.6.33.2 /tmp/rsynctest
umount CLOUD_MNT_PT
rm -rf /tmp/rsynctest
done
) &








