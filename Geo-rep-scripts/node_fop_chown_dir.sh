source ./config
fop="chown directory"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
chown -R lakshmipathi:root $MNT_PT/d1/d2/d3/d4/d5
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
