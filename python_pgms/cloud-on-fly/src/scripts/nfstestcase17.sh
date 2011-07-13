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

( dbench -D CLOUD_MNT_PT/`hostname`/$i -t 86400 ) &








