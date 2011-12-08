source ./config
for i in {1..25};do
/opt/glusterfs/$VERSION/sbin/gluster volume set $VOLNAME xtime-marker off
/opt/glusterfs/$VERSION/sbin/gluster volume info $VOLNAME
ps aux | grep gluster
sleep 2;
/opt/glusterfs/$VERSION/sbin/gluster volume set $VOLNAME xtime-marker on
/opt/glusterfs/$VERSION/sbin/gluster volume info $VOLNAME
ps aux | grep gluster
sleep 2;
done
