source ./config
fop="unlink file test"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "File contents" > $MNT_PT/d1/d2/d3/d4/d5/file.txt
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
rm -rf  $MNT_PT/d1/d2/d3/d4/d5/file.txt
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
