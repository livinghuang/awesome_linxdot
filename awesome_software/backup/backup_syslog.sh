#!/bin/sh
###############################################################################
# 系統 Log 備份腳本 for Linxdot
# - 將 /overlay/log/messages 備份到 /root/backup
# - 檢查 overlay 剩餘空間，低於 5% 刪除最舊備份
# - 備份成功後清空 messages 並重啟 log 服務
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
LOG_FILE="/overlay/log/messages"
BACKUP_DIR="/root/backup"
LOGTAG="backup_syslog"
DATE=$(date +%Y%m%d_%H%M%S)

# overlay mount detection
OVERLAY_DIR=$(mount | awk '$3=="/overlay"{print $3}')
[ -z "$OVERLAY_DIR" ] && OVERLAY_DIR="/"
USED=$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","");print $(NF-1)}')
FREE=$((100 - USED))

# low-space eviction
if [ "$FREE" -lt 5 ]; then
  logger -t "$LOGTAG" "[WARN] Low disk space ($FREE%), deleting oldest messages_* backup"
  ls -1tr "$BACKUP_DIR"/messages_*.log 2>/dev/null | head -n 1 | xargs -r rm -f
fi

mkdir -p "$BACKUP_DIR"

if [ -f "$LOG_FILE" ]; then
  DEST="$BACKUP_DIR/messages_$DATE.log"
  if cp "$LOG_FILE" "$DEST"; then
    logger -t "$LOGTAG" "[INFO] messages backed up to $DEST"
    : > "$LOG_FILE"
  else
    logger -t "$LOGTAG" "[ERROR] Failed to copy $LOG_FILE to $DEST"
    exit 1
  fi
fi

# restart log service (logd or log)
if /etc/init.d/logd status >/dev/null 2>&1; then
  /etc/init.d/logd restart
else
  /etc/init.d/log restart
fi
