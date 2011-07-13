cd CLOUD_MNT_PT
for i in {1..6}; 
do 
if [ -d $i ];
then echo " ye"; 
else mkdir -p $i;
break;
fi;
done
cd $i
/opt/qa/tools/32-bit/iozone -a -b output.xls > txt.out &
touch $i.txt
echo " CLOUD_MNT_PT "  > $i.txt

