#Simple script to aws add machines cloud table
#AWS_file.txt -- shoud have list of machine names like, ec2-67-202-6-25.compute-1.amazonaws.com
#Note : For NFS- First client_pool table record will acts as NFS server.

if [ ! $# -eq 2 ]
	then
	echo "Usage:cloud_add.sh [server/client] AWS_file.txt"
	exit
	fi

table=$1_pool
file=$2
dbpath="/usr/share/cloud/cloud_db.sqlite"

for sys in `cat $file`
do

part1=`echo $sys | cut -f1 -d'.' | cut -d'-' -f2`
part2=`echo $sys | cut -f1 -d'.' | cut -d'-' -f3`
part3=`echo $sys | cut -f1 -d'.' | cut -d'-' -f4`
part4=`echo $sys | cut -f1 -d'.' | cut -d'-' -f5`

ipaddr=$part1"."$part2"."$part3"."$part4

qry="insert into  $table   values (\"$sys\",\"free\",\"$ipaddr\");"
echo "Running Query:" $qry

sqlite3 $dbpath << EOF 
$qry
EOF
done

