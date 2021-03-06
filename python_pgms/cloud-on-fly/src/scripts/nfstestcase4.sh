#EDIT NFSSERVER MANUALLY
cd CLOUD_MNT_PT

mkdir `hostname`

for i in {1..6};
do
if [ -d $i ];
then echo " yes";
else mkdir -p $i;
break;
fi;
done
cd CLOUD_MNT_PT/`hostname`/$i

mkdir -p /opt/qa/nfstesting/tc4
cd /opt/qa/nfstesting/tc4
if [ ! -f /opt/qa/nfstesting/tc4/linux-2.6.33.2.tar.bz2 ] 
then
wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
tar -xjf linux-2.6.33.2.tar.bz2
fi
mkdir -p CLOUD_MNT_PT/`hostname`/$i
cd /tmp
umount CLOUD_MNT_PT
( for k in $(seq 1 1000);
do
mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch "  CLOUD_MNT_PT
cp ­-R /opt/qa/nfstesting/tc4/linux-2.6.33.2 CLOUD_MNT_PT/`hostname`/$i
find CLOUD_MNT_PT/`hostname`/$i
rm ­-rf CLOUD_MNT_PT/`hostname`/$i/*
umount CLOUD_MNT_PT
done
) &








