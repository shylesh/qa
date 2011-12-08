source ./config
#/opt/glusterfs/$VERSION/sbin/glusterfs --volfile-server=$SERVER --volfile-id=$VOLNAME --client-pid=-1 $MNT_PT_NEG_PID
getfattr -n trusted.glusterfs.volume-mark $MNT_PT_NEG_PID
