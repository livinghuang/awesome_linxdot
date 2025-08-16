#!/bin/sh
###############################################################################
# 測試腳本：驗證 backup_run.sh --test 與 cron job 是否能正常觸發
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
LOGFILE="/var/log/backup_test.log"

DATE="$(date '+%F %T')"
echo "[$DATE] backup_test.sh executed OK" >> "$LOGFILE"

exit 0
