if [ -d /opt/qa/tools ]; 
then 
echo " ";
else
modprobe fuse
mkdir -p  /opt
export LD_LIBRARY_PATH=/usr/local/lib
/old_opt/glusterfs/2.0.6/sbin/glusterfs -f /root/cfg.vol /opt -l /tmp/client.log
fi
