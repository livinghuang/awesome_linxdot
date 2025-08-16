#!/bin/sh
###############################################################################
# Test script: verify cron & pipeline without heavy IO
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
LOGFILE="/var/log/backup_test.log"
DATE="$(date '+%F %T')"

# ensure log dir exists (OpenWrt tmpfs)
mkdir -p "$(dirname "$LOGFILE")"

echo "[$DATE] backup_test.sh executed OK" >> "$LOGFILE"
logger -t backup_test "[INFO] executed OK at $DATE"
exit 0
