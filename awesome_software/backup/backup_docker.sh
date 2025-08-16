#!/bin/sh
###############################################################################
# Docker 日誌備份腳本 for Linxdot
# 功能：
#   - 將 /opt/docker/containers 下所有 .log 檔案打包壓縮備份
#   - 備份檔名包含日期時間戳記，儲存在 /root/docker_log_backup
#   - 保留最近 7 天的備份，刪除更舊檔案並統計數量
#   - 每次備份完成後記錄至 /var/log/docker_log_backup.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC=/opt/docker/containers
DST=/root/docker_log_backup
LOGFILE=/var/log/docker_log_backup.log
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

# 建立備份儲存目錄
mkdir -p "$DST"

# 檢查來源資料夾是否存在，不存在則退出
[ -d "$SRC" ] || exit 0
cd "$SRC" || exit 1

# 打包 .log 檔案
ARCHIVE="$DST/docker_logs_$DATE.tar.gz"
find . -type f -name "*.log" -print0 | tar --null -czf "$ARCHIVE" --files-from=-

# 刪除 7 天前的備份，並記錄刪掉的檔案
DELETED_COUNT=0
find "$DST" -type f -name "docker_logs_*.tar.gz" -mtime +$KEEP_DAYS | while read f; do
  echo "[$(date '+%F %T')] Deleted old backup: $f" >> "$LOGFILE"
  rm -f "$f"
  DELETED_COUNT=$((DELETED_COUNT+1))
done

# 紀錄備份完成時間與檔案名稱
echo "[$(date '+%F %T')] Backup created: $ARCHIVE" >> "$LOGFILE"
echo "[$(date '+%F %T')] Cleanup finished, deleted $DELETED_COUNT old backups" >> "$LOGFILE"
