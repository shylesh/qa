source ./config
fop="symlink (for dir) unlink test"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
ln -s $MNT_PT/d1 $MNT_PT/sld1
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
rm -rf $MNT_PT/sld1
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
