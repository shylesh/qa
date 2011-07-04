#set -x
#check for file named in 5-digit numbers and increment it - sanity_counter
cd /sanity/test/counter
ls [0-9][0-9][0-9][0-9][0-9] | while read fn;
do
id=$fn
new=`expr $id + 1`
rm $id
echo $id #sanity_id 
if [ $new -eq 100000 ]
	then
		touch 10000
		
	else
		touch $new
fi
done
