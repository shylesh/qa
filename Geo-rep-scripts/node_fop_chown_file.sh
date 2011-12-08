source ./config
fop="chown file"
rm -rf $MNT_PT/*
mkdir $MNT_PT/d1/d2/d3/d4/d5 -p
echo "Chown for a file" > $MNT_PT/d1/d2/d3/d4/d5/file.txt
echo "Before $fop"
show_backend
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
echo "AFTER $fop"
chown -R lakshmipathi:root $MNT_PT/d1/d2/d3/d4/d5/file.txt
$XTIME_PATH/xtime.rb $MNT_PT_NEG_PID
show_backend
