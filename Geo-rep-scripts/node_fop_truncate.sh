source ./config
fop="truncate"
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "hello..this is called a truncate test file." > $MNT_PT/d1/d2/d3/d4/d5/file.txt
echo "Before $fop"
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
echo "AFTER $fop"
truncate -s $TRUNCATE_SIZE $MNT_PT/d1/d2/d3/d4/d5/file.txt
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
