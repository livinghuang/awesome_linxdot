#!/bin/sh
###############################################################################
# 系統 Log 備份腳本 for Linxdot
# 功能：
#   - 將 /overlay/log/messages 備份到 /root/backup
#   - 檢查 overlay 分區空間，若剩餘不足 5%，刪除最舊備份以釋放空間
#   - 備份完後清空 messages 並重啟 log 服務
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
LOG_FILE="/overlay/log/messages"
BACKUP_DIR="/root/backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 取得 overlay 分區使用率
OVERLAY_DIR=$(mount | awk '$3=="/overlay"{print $3}')
[ -z "$OVERLAY_DIR" ] && OVERLAY_DIR="/"
USED=$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","");print $(NF-1)}')
FREE=$((100 - USED))

# 若剩餘空間少於 5%，刪除最舊備份
if [ "$FREE" -lt 5 ]; then
    logger -t log_backup "[WARN] Low disk space ($FREE%), deleting oldest log"
    ls -1tr "$BACKUP_DIR"/messages_*.log 2>/dev/null | head -n 1 | xargs -r rm -f
fi

# 建立備份資料夾
mkdir -p "$BACKUP_DIR"

# 備份並確認成功後再清空
if [ -f "$LOG_FILE" ]; then
    DEST="$BACKUP_DIR/messages_$DATE.log"
    if cp "$LOG_FILE" "$DEST"; then
        logger -t log_backup "[INFO] messages backed up to $DEST"
        : > "$LOG_FILE"
    else
        logger -t log_backup "[ERROR] Failed to backup $LOG_FILE"
    fi
fi

# 重啟 log 服務（根據系統不同可能是 log 或 logd）
if /etc/init.d/logd status >/dev/null 2>&1; then
    /etc/init.d/logd restart
else
    /etc/init.d/log restart
fi
