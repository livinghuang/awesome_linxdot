#!/bin/sh
###############################################################################
# set_backup_test_in_cron.sh
# 功能：
#   - 自動在 root crontab 中加入測試排程
#   - 每分鐘執行一次 backup_run.sh --test
#   - 若已存在相同條目則不重複新增
###############################################################################

CRON_LINE="* * * * * /opt/awesome_linxdot/awesome_software/backup/backup_run.sh --test"

# 讀取目前 crontab
crontab -l 2>/dev/null | grep -F "$CRON_LINE" >/dev/null
if [ $? -eq 0 ]; then
  echo "[INFO] Cron job already exists, no changes made."
else
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo "[INFO] Cron job added: $CRON_LINE"
fi

# 顯示目前 crontab
echo "========== Current crontab =========="
crontab -l
echo "====================================="
