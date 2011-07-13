LOG="/opt/qa/nfstesting/status.log"
hostname >> $LOG
date >> $LOG
ps -fp $(pgrep -d, -x iozone) >> $LOG
ps -fp $(pgrep -d, -x dbench) >> $LOG
ps -fp $(pgrep -d, -x fio) >> $LOG
ps -fp $(pgrep -d, -x fileop) >> $LOG
ps -fp $(pgrep -d, -x bonnie) >> $LOG
echo "=====================================================" >> $LOG

