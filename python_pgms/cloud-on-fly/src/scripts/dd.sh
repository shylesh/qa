cd CLOUD_MNT_PT
mkdir -p `hostname`/dd
cd `hostname`/dd
for i in {1..50};
do
dd if=/dev/zero of=CLOUD_MNT_PT/`hostname`/dd bs=4Kb  count=25
done
