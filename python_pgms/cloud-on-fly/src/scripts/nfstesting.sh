#EDIT NFSSERVER MANUALLY
cd CLOUD_MNT_PT

for i in {1..5};
do
if [ -d $i ];
then echo " yes";
else mkdir -p $i;
break;
fi;
done
cd CLOUD_MNT_PT/$i

mkdir -p /opt/qa/nfstesting/laks
cd /opt/qa/nfstesting/laks
if [ ! -f /opt/qa/nfstesting/laks/linux-2.6.33.2.tar.bz2 ] 
then
wget http://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.2.tar.bz2
tar -xjf linux-2.6.33.2.tar.bz2
fi
mkdir -p CLOUD_MNT_PT/$i
cp ­-R linux-2.6.33.2 CLOUD_MNT_PT/$i
umount CLOUD_MNT_PT

for i in $(seq 1 500);
do
mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch " + CLOUD_MNT_PT
tar ­-c CLOUD_MNT_PT/$i/linux-2.6.33.2 > CLOUD_MNT_PT/$i/tarball.tar
rm ­-f CLOUD_MNT_PT/$i/tarball.tar
umount CLOUD_MNT_PT
done
