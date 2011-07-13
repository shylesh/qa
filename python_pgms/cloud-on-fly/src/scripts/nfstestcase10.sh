#nfstestcase:10
#EDIT NFSSERVER MANUALLY
mkdir -p /opt/qa/nfstesting/log/tc10
( for k in $(seq 1 5000);
do
mount "ec2-67-202-6-25.compute-1.amazonaws.com:/statprefetch -o noresvport "  CLOUD_MNT_PT
df >> /opt/qa/nfstesting/log/tc10/hostname.log
umount CLOUD_MNT_PT
done
) &








