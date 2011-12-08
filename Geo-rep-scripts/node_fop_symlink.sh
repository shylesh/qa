source ./config
fop="symlink test"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
ln -s $MNT_PT/d1 $MNT_PT/sld1
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
