#!/bin/sh
###############################################################################
# 備份打包封存腳本
# - Pack /root/backup into /root/backup_YYYYmmdd_HHMMSS.tar.gz
# - Skip if empty; rotate 7 days; log to /var/log/backup_pack.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC="/root/backup"
DST="/root"
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$DST/backup_$DATE.tar.gz"
LOGFILE="/var/log/backup_pack.log"
RETENTION_DAYS=7

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"; logger -t "backup_pack" "$*"; }

if [ ! -d "$SRC" ] || [ -z "$(ls -A "$SRC" 2>/dev/null)" ]; then
  log "[WARN] Source folder $SRC not found or empty, skip."
  exit 0
fi

log "[INFO] Start packing $SRC -> $ARCHIVE"
if tar -C "$SRC" -czf "$ARCHIVE" .; then
  log "[INFO] Pack success: $ARCHIVE"
else
  log "[ERROR] Pack failed: $ARCHIVE"
  rm -f "$ARCHIVE"
  exit 1
fi

# rotate
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
