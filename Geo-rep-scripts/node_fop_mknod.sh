source ./config
fop="mknod test"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
mknod  $MNT_PT/d1/ttyS4 c 4 68
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
