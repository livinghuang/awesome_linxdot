#!/bin/sh

echo "===== Linxdot One-Key Uninstaller Start ====="

# Step 1: Remove all installed scripts
echo "Removing scripts from /usr/bin/..."

rm -f /usr/bin/log_backup.sh
rm -f /usr/bin/backup_pack.sh
rm -f /usr/bin/cleanup_old_backup.sh
rm -f /usr/bin/system_health_check.sh

echo "Scripts removed."

# Step 2: Clean crontab entries
echo "Cleaning crontab..."

if [ -f /etc/crontabs/root ]; then
    sed -i '/\/usr\/bin\/log_backup.sh/d' /etc/crontabs/root
    sed -i '/mkdir -p \/root\/backup/d' /etc/crontabs/root
    sed -i '/\/usr\/bin\/backup_pack.sh/d' /etc/crontabs/root
    sed -i '/\/usr\/bin\/cleanup_old_backup.sh/d' /etc/crontabs/root
    sed -i '/\/usr\/bin\/system_health_check.sh/d' /etc/crontabs/root
    sed -i '/\/sbin\/reboot/d' /etc/crontabs/root
fi

echo "Crontab cleaned."

# Step 3: Restart cron service
echo "Restarting cron service..."
/etc/init.d/cron restart

# Step 4: Final Check
echo "===== Linxdot One-Key Uninstaller Completed ====="
