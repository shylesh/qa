cd CLOUD_MNT_PT
echo "Hostname ---- pwd  ---- df --- lsof" >> /opt/qa/nfstesting/lsof.out
hostname >> /opt/qa/nfstesting/lsof.out
pwd >> /opt/qa/nfstesting/lsof.out 
df >> /opt/qa/nfstesting/lsof.out
echo "lsof" >> /opt/qa/nfstesting/lsof.out
lsof CLOUD_MNT_PT >> /opt/qa/nfstesting/lsof.out
echo "---" >> /opt/qa/nfstesting/lsof.out
