#!/bin/sh
###############################################################################
# remove_backup_test_from_cron.sh
# 功能：
#   - 移除 root crontab 中的 backup_run.sh --test 排程
###############################################################################

CRON_LINE="/opt/awesome_linxdot/awesome_software/backup/backup_run.sh --test"

# 過濾掉指定的 cron line
crontab -l 2>/dev/null | grep -v "$CRON_LINE" | crontab -

echo "[INFO] Removed cron job containing: $CRON_LINE"

# 顯示目前 crontab
echo "========== Current crontab =========="
crontab -l
echo "====================================="
