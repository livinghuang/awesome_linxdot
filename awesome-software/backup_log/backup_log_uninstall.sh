#!/bin/sh
###############################################################################
# Linxdot System Uninstaller
###############################################################################

echo "===== Linxdot System Uninstaller Start ====="
echo
echo "⚠️  這會移除所有備份腳本及其對應的 crontab 任務！"
echo "    之後將失去自動備份、健康檢查與 watchdog 功能。"
echo

read -p "Are you sure you want to continue? (yes/no): " confirm
case "$confirm" in
  y|Y|yes|YES) ;;                          # 允許 y / yes
  *) echo "Uninstall cancelled."; exit 0 ;;
esac

# -----------------------------------------------------------------------------
# 1. 移除腳本（/usr/bin symlink 與 /usr/share/linxdot 本體）
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

for f in $BIN_LIST; do
    rm -f "/usr/bin/$f"
    rm -f "/usr/share/linxdot/$f"
done

# -----------------------------------------------------------------------------
# 2. 清理 crontab 相關排程
# -----------------------------------------------------------------------------
CRONTAB=/etc/crontabs/root
echo "Cleaning crontab entries ..."

KEYWORDS="
log_backup.sh
backup_pack.sh
cleanup_old_backup.sh
system_health_check.sh
backup_docker_log.sh
system_watchdog.sh
backup_etc.sh
mkdir -p /root/backup
cron_reboot
/sbin/reboot
"

# 逐條目刪除；若不存在不報錯
while read -r kw; do
    [ -n "$kw" ] && sed -i "\#$kw#d" "$CRONTAB" 2>/dev/null || true
done <<EOF
$KEYWORDS
EOF

# -----------------------------------------------------------------------------
# 3. 清除版本標記
# -----------------------------------------------------------------------------
rm -f /etc/linxdot_installer.version

# -----------------------------------------------------------------------------
# 4. 重新啟動 cron
# -----------------------------------------------------------------------------
echo "Restarting cron service ..."
/etc/init.d/cron restart

# -----------------------------------------------------------------------------
# 5. 完成
# -----------------------------------------------------------------------------
echo
echo "===== Linxdot System Uninstaller Completed ====="
