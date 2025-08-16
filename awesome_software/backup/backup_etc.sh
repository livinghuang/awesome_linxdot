#!/bin/sh
###############################################################################
# /etc 設定備份腳本
# - Snapshot /etc into /root/backup/etc_YYYYmmdd_HHMMSS
# - Keep last 7 days; log to /var/log/backup_etc.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
DATE=$(date +%Y%m%d_%H%M%S)
DIR="/root/backup/etc_$DATE"
LOGFILE="/var/log/backup_etc.log"
KEEP_DAYS=7

mkdir -p "$DIR"

# copy preserving perms; include hidden, ignore errors for special files
cp -a /etc/* "$DIR/" 2>/dev/null || true
cp -a /etc/.* "$DIR/" 2>/dev/null || true

echo "[$(date '+%F %T')] Backup etc -> $DIR" >> "$LOGFILE"

# cleanup old etc snapshots
for f in $(find /root/backup -maxdepth 1 -type d -name "etc_*" -mtime +$KEEP_DAYS); do
  echo "[$(date '+%F %T')] Deleted old etc backup: $f" >> "$LOGFILE"
  rm -rf "$f"
done
