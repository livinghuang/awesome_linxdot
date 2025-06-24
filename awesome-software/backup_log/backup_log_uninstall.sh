#!/bin/sh
###############################################################################
# Linxdot System Uninstaller
###############################################################################

echo "===== Linxdot System Uninstaller Start ====="
echo ""
echo "⚠️  This will remove all backup scripts and related crontab entries!"
echo "    You may lose scheduled auto-backup, health checks, and watchdogs."
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

# -----------------------------------------------------------------------------
# 1. 移除已安裝的 script symlinks（/usr/bin）與 script 本體（/usr/share/linxdot）
# -----------------------------------------------------------------------------
BIN_LIST="
log_backup.sh
backup_pack.sh
cleanup_old_backup.sh
system_health_check.sh
backup_docker_log.sh
system_watchdog.sh
backup_etc.sh
"

for script in $BIN_LIST; do
    rm -f "/usr/bin/$script"
    rm -f "/usr/share/linxdot/$script"
done

# -----------------------------------------------------------------------------
# 2. 清除 /etc/crontabs/root 中的相關排程
# -----------------------------------------------------------------------------
CRONTAB=/etc/crontabs/root
echo "Cleaning crontab entries..."

for keyword in \
    log_backup.sh \
    backup_pack.sh \
    cleanup_old_backup.sh \
    system_health_check.sh \
    backup_docker_log.sh \
    system_watchdog.sh \
    backup_etc.sh \
    mkdir\ -p\ /root/backup \
    cron_reboot \
    /sbin/reboot
do
    sed -i "/$keyword/d" "$CRONTAB"
done

# -----------------------------------------------------------------------------
# 3. 移除安裝版本紀錄檔
# -----------------------------------------------------------------------------
rm -f /etc/linxdot_installer.version

# -----------------------------------------------------------------------------
# 4. 重啟 cron 確保變更生效
# -----------------------------------------------------------------------------
echo "Restarting cron service..."
/etc/init.d/cron restart

# -----------------------------------------------------------------------------
# 5. 完成訊息
# -----------------------------------------------------------------------------
echo ""
echo "===== Linxdot System Uninstaller Completed ====="
