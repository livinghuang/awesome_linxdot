#!/bin/sh
###############################################################################
# Docker 日誌備份腳本 for Linxdot
# - Pack /opt/docker/containers/*.log to /root/docker_log_backup
# - Keep last 7 days, delete older bundles (with counts)
# - Write to /var/log/docker_log_backup.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SRC="/opt/docker/containers"
DST="/root/docker_log_backup"
LOGFILE="/var/log/docker_log_backup.log"
DATE=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7

mkdir -p "$DST"
[ -d "$SRC" ] || exit 0
cd "$SRC" || exit 1

ARCHIVE="$DST/docker_logs_$DATE.tar.gz"
# gather only regular *.log files
find . -type f -name "*.log" -print0 | tar --null -czf "$ARCHIVE" --files-from=-

# delete old archives with accounting
DELETED=0
for f in $(find "$DST" -type f -name "docker_logs_*.tar.gz" -mtime +$KEEP_DAYS); do
  echo "[$(date '+%F %T')] Deleted old backup: $f" >> "$LOGFILE"
  rm -f "$f"
  DELETED=$((DELETED+1))
done

echo "[$(date '+%F %T')] Backup created: $ARCHIVE" >> "$LOGFILE"
echo "[$(date '+%F %T')] Cleanup finished, deleted $DELETED old backups" >> "$LOGFILE"
