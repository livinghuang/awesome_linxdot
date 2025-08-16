#!/bin/sh
###############################################################################
# set_backup_daily_in_cron.sh
# - Add daily production cron (default 03:00) for backup_run.sh
# Environment: TIME="M H" e.g. TIME="30 2" for 02:30
###############################################################################

BACKUP_SCRIPT="/opt/awesome_linxdot/awesome_software/backup/backup_run.sh"
HOUR="${HOUR:-3}"
MIN="${MIN:-0}"
CRON_TIME="$MIN $HOUR * * *"
CRON_LINE="$CRON_TIME $BACKUP_SCRIPT"

if crontab -l 2>/dev/null | grep -F "$BACKUP_SCRIPT" >/dev/null; then
  echo "[INFO] Cron job already exists, skip adding."
else
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo "[INFO] Added cron job: $CRON_LINE"
fi

echo "========== Current crontab =========="
crontab -l
echo "====================================="
