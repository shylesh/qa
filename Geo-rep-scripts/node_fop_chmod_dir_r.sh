source ./config
fop="chmod Recursively"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
chmod -R 777 $MNT_PT/d1
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
