#!/bin/sh
###############################################################################
# Docker 日誌備份腳本 for Linxdot
# 功能：
#   - 將 /opt/docker/containers 下所有 .log 檔案打包壓縮備份
#   - 備份檔名包含日期時間戳記，儲存在 /root/docker_log_backup
#   - 保留最近 7 份備份，刪除較舊檔案
#   - 每次備份完成後記錄至 /var/log/docker_log_backup.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC=/opt/docker/containers
DST=/root/docker_log_backup
LOGFILE=/var/log/docker_log_backup.log
DATE=$(date +%Y%m%d_%H%M%S)
KEEP=7

# 建立備份儲存目錄
mkdir -p "$DST"

# 檢查來源資料夾是否存在，不存在則退出
[ -d "$SRC" ] || exit 0

# 切換到來源資料夾
cd "$SRC" || exit 1

# 打包 .log 檔案
ARCHIVE="$DST/docker_logs_$DATE.tar.gz"
find . -name "*.log" -print0 | tar --null -czf "$ARCHIVE" --files-from=-

# 刪除過期備份（保留最近 $KEEP 天）
find "$DST" -name "docker_logs_*.tar.gz" -mtime +$KEEP -exec rm -f {} \;

# 紀錄備份完成時間與檔案名稱
echo "$(date '+%F %T') Backup created: $ARCHIVE" >> "$LOGFILE"
