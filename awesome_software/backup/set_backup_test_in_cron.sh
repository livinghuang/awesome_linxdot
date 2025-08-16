#!/bin/sh
###############################################################################
# set_backup_test_in_cron.sh
# - Add per-minute test cron for backup_run.sh --test
###############################################################################

CRON_LINE="* * * * * /opt/awesome_linxdot/awesome_software/backup/backup_run.sh --test"

crontab -l 2>/dev/null | grep -F "$CRON_LINE" >/dev/null
if [ $? -eq 0 ]; then
  echo "[INFO] Cron job already exists, no changes made."
else
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo "[INFO] Cron job added: $CRON_LINE"
fi

echo "========== Current crontab =========="
crontab -l
echo "====================================="
