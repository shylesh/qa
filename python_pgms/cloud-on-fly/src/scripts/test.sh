cd CLOUD_MNT_PT
for i in {1..10}; do dd if=/dev/zero  of=$i.txt bs=4KB count=10; done
