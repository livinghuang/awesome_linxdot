#!/bin/sh
###############################################################################
# Linxdot: 設定備份排程腳本
# 功能：
#   - 自動將 /root/backup/backup_run.sh 加入 cron 任務
#   - 預設每天凌晨 2 點執行
#   - 避免重複加入
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
CRON_FILE="/etc/crontabs/root"
BACKUP_CMD="/root/backup/backup_run.sh"
SCHEDULE="0 2 * * *"

# 確保 backup_run.sh 存在且可執行
if [ ! -x "$BACKUP_CMD" ]; then
  echo "[ERROR] $BACKUP_CMD not found or not executable."
  exit 1
fi

# 建立 cron 檔案（若不存在）
touch "$CRON_FILE"

# 檢查是否已存在同樣的排程
if grep -q "$BACKUP_CMD" "$CRON_FILE"; then
  echo "[INFO] Cron job already exists: $SCHEDULE $BACKUP_CMD"
else
  echo "[INFO] Adding cron job: $SCHEDULE $BACKUP_CMD"
  echo "$SCHEDULE $BACKUP_CMD" >> "$CRON_FILE"
fi

# 套用新的 crontab
/etc/init.d/cron restart >/dev/null 2>&1 || /etc/init.d/crond restart >/dev/null 2>&1

echo "[INFO] Cron job set successfully."
exit 0
