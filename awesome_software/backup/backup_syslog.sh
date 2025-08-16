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

# 若剩餘空間少於 5%，記錄警告並刪除最舊的 log 備份
[ "$FREE" -lt 5 ] && logger -t log_backup "[WARN] Low disk space ($FREE%)" && \
    ls -1t "$BACKUP_DIR"/messages_*.log 2>/dev/null | tail -n 1 | xargs -r rm -f

# 建立備份資料夾（如未存在）
mkdir -p "$BACKUP_DIR"

# 若 messages 存在，則備份後清空它
[ -f "$LOG_FILE" ] && cp "$LOG_FILE" "$BACKUP_DIR/messages_$DATE.log" && : > "$LOG_FILE"

# 重新啟動 log 服務
/etc/init.d/log restart
