#!/bin/sh

echo "===== Linxdot System Uninstaller Start ====="
echo ""
echo "Warning: This will remove all backup scripts and related crontab entries!"
read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Remove scripts
rm -f /usr/bin/log_backup.sh
rm -f /usr/bin/backup_pack.sh
rm -f /usr/bin/cleanup_old_backup.sh
rm -f /usr/bin/system_health_check.sh
rm -f /usr/bin/backup_docker_log.sh

# Clean crontab entries
sed -i '/log_backup.sh/d' /etc/crontabs/root
sed -i '/backup_pack.sh/d' /etc/crontabs/root
sed -i '/cleanup_old_backup.sh/d' /etc/crontabs/root
sed -i '/system_health_check.sh/d' /etc/crontabs/root
sed -i '/backup_docker_log.sh/d' /etc/crontabs/root
sed -i '/mkdir -p \/root\/backup/d' /etc/crontabs/root
sed -i '/\/sbin\/reboot/d' /etc/crontabs/root

# Restart cron service
echo "Restarting cron service..."
/etc/init.d/cron restart

echo "===== Linxdot System Uninstaller Completed ====="
