#!/bin/sh
###############################################################################
# 備份清理腳本 for Linxdot
# 功能：
#   - 刪除 7 天前的備份檔案（壓縮包、log、/etc 備份資料夾）
#   - 保持儲存空間清潔
#   - 將執行結果寫入 log 檔：/var/log/backup_cleanup.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
KEEP_DAYS=7
LOGFILE="/var/log/backup_cleanup.log"

echo "[$(date '+%F %T')] Start cleanup" >> "$LOGFILE"

# 清理舊檔案（並記錄被刪掉的檔名）
find /root -name "backup_*.tar.gz" -type f -mtime +"$KEEP_DAYS" -print -delete >> "$LOGFILE"
find /root/backup -name "messages_*.log" -type f -mtime +"$KEEP_DAYS" -print -delete >> "$LOGFILE"
find /root/backup -name "etc_*" -type d -mtime +"$KEEP_DAYS" -print -exec rm -rf {} \; >> "$LOGFILE"
find /root/docker_log_backup -name "docker_logs_*.tar.gz" -type f -mtime +"$KEEP_DAYS" -print -delete >> "$LOGFILE"

echo "[$(date '+%F %T')] Cleanup completed" >> "$LOGFILE"
