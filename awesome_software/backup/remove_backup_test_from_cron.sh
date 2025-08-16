#!/bin/sh
###############################################################################
# remove_backup_test_from_cron.sh
# - Remove the test cron entry for backup_run.sh --test
###############################################################################

CRON_LINE="/opt/awesome_linxdot/awesome_software/backup/backup_run.sh --test"
crontab -l 2>/dev/null | grep -v "$CRON_LINE" | crontab -
echo "[INFO] Removed cron job containing: $CRON_LINE"
echo "========== Current crontab =========="
crontab -l
echo "====================================="
