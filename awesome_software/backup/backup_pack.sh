#!/bin/sh
###############################################################################
# 備份打包封存腳本
# 功能：
#   - 將 /root/backup 資料夾內容整個壓縮成 backup_時間戳.tar.gz
#   - 存放至 /root 目錄下
#   - 過期清理（只保留 7 天）
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC="/root/backup"              # 備份來源資料夾
DST="/root"                      # 壓縮檔儲存位置
DATE=$(date +%Y%m%d_%H%M%S)      # 時間戳記
ARCHIVE="$DST/backup_$DATE.tar.gz"
LOGFILE="/var/log/backup_pack.log"
RETENTION_DAYS=7                 # 保留天數

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"
    logger -t "backup_pack" "$*"
}

# 若來源資料夾不存在或是空的就跳過
if [ ! -d "$SRC" ] || [ -z "$(ls -A "$SRC")" ]; then
    log "[WARN] Source folder $SRC not found or empty, skip."
    exit 0
fi

# 打包壓縮
log "[INFO] Start packing $SRC -> $ARCHIVE"
if tar -C "$SRC" -czf "$ARCHIVE" .; then
    log "[INFO] Pack success: $ARCHIVE"
else
    log "[ERROR] Pack failed: $ARCHIVE"
    rm -f "$ARCHIVE"
    exit 1
fi

# 清理過期備份檔
log "[INFO] Cleaning backups older than $RETENTION_DAYS days..."
OLD_FILES=$(find "$DST" -maxdepth 1 -type f -name "backup_*.tar.gz" -mtime +"$RETENTION_DAYS")
COUNT=$(echo "$OLD_FILES" | grep -c . || true)

if [ "$COUNT" -gt 0 ]; then
    echo "$OLD_FILES" | while read -r f; do
        rm -f "$f" && log "[INFO] Removed old backup: $f"
    done
    log "[INFO] Cleanup done, removed $COUNT files"
else
    log "[INFO] No old backups found"
fi

log "[INFO] Backup pack completed."
exit 0
