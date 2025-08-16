#!/bin/sh
###############################################################################
# 備份清理腳本 for Linxdot
# - Delete old backup artifacts to keep storage clean (7 days by default)
# - Logs deletions and totals to /var/log/backup_cleanup.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
KEEP_DAYS="${KEEP_DAYS:-7}"
LOGFILE="/var/log/backup_cleanup.log"

echo "[$(date '+%F %T')] Start cleanup (older than $KEEP_DAYS days)" >> "$LOGFILE"

delete_and_count() {
  pattern="$1"
  dir="$2"
  COUNT=0
  for f in $(find "$dir" -type f -name "$pattern" -mtime +"$KEEP_DAYS" 2>/dev/null); do
    echo "[$(date '+%F %T')] delete: $f" >> "$LOGFILE"
    rm -f "$f"
    COUNT=$((COUNT+1))
  done
  echo $COUNT
}

# tarballs in /root
C1=$(delete_and_count "backup_*.tar.gz" "/root")
# docker bundles
C2=$(delete_and_count "docker_logs_*.tar.gz" "/root/docker_log_backup")
# full bundles
C3=$(delete_and_count "logs_*.tar.gz" "/root/log_backup")

# etc snapshots (directories)
DCOUNT=0
for d in $(find /root/backup -maxdepth 1 -type d -name "etc_*" -mtime +"$KEEP_DAYS" 2>/dev/null); do
  echo "[$(date '+%F %T')] rmdir: $d" >> "$LOGFILE"
  rm -rf "$d"
  DCOUNT=$((DCOUNT+1))
done

# old messages copies
C4=0
for f in $(find /root/backup -type f -name "messages_*.log" -mtime +"$KEEP_DAYS" 2>/dev/null); do
  echo "[$(date '+%F %T')] delete: $f" >> "$LOGFILE"
  rm -f "$f"
  C4=$((C4+1))
done

TOTAL=$((C1+C2+C3+C4+DCOUNT))
echo "[$(date '+%F %T')] Cleanup completed. files:$((C1+C2+C3+C4)) dirs:$DCOUNT total:$TOTAL" >> "$LOGFILE"
exit 0
