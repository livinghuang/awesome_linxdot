#!/bin/sh
###############################################################################
# set_backup_daily_in_cron.sh
# 功能：
#   - 在 root crontab 中新增每天一次的正式備份排程
#   - 預設每天凌晨 03:00 執行 backup_run.sh
###############################################################################

BACKUP_SCRIPT="/opt/awesome_linxdot/awesome_software/backup/backup_run.sh"
CRON_TIME="0 3 * * *"
CRON_LINE="$CRON_TIME $BACKUP_SCRIPT"

# 先檢查是否已存在相同排程
if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT"; then
    echo "[INFO] Cron job already exists, skip adding."
else
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    echo "[INFO] Added cron job: $CRON_LINE"
fi

# 顯示目前 crontab
echo "========== Current crontab =========="
crontab -l
echo "====================================="
