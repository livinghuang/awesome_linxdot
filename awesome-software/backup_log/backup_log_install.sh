#!/bin/sh

# ===== Linxdot One-Key System Installer Start =====
echo "===== Linxdot One-Key System Installer Start ====="

# Step 1: Create overlay log directory to store persistent logs
if [ ! -d /overlay/log ]; then
    echo "Creating /overlay/log..."
    mkdir -p /overlay/log
    chmod 755 /overlay/log
else
    echo "/overlay/log already exists."
fi

# Step 2: Configure system log location and size
# 將 log 設定存放在 overlay 上，使其可在 reboot 後保留
echo "Configuring system log settings..."
uci batch <<EOF
set system.@system[0].log_file='/overlay/log/messages'
set system.@system[0].log_size='512'
commit system
EOF

# Restart system logging service
# 重啟系統日誌服務
echo "Restarting log service..."
/etc/init.d/log restart

# Step 3: Create log backup script
# 建立 log 備份腳本，定期備份 overlay/log/messages
cat <<'EOF' > /usr/bin/log_backup.sh
#!/bin/sh
LOG_FILE="/overlay/log/messages"
BACKUP_DIR="/root/backup"
DATE=$(date +%Y%m%d_%H%M%S)
OVERLAY_DIR="/overlay"

mkdir -p "$BACKUP_DIR"

FREE_PERCENT=$(df "$OVERLAY_DIR" | awk 'NR==2 {print $(NF-1)}' | tr -d '%')

if [ "$FREE_PERCENT" -lt 5 ]; then
    echo "[WARN] Low disk space ($FREE_PERCENT%) - Deleting oldest backup..." | logger -t log_backup
    OLDEST_BACKUP=$(ls -t $BACKUP_DIR/messages_*.log 2>/dev/null | tail -n 1)
    if [ -n "$OLDEST_BACKUP" ]; then
        rm -f "$OLDEST_BACKUP"
        echo "[INFO] Oldest backup $OLDEST_BACKUP deleted." | logger -t log_backup
    fi
fi

if [ -f "$LOG_FILE" ]; then
    cp "$LOG_FILE" "$BACKUP_DIR/messages_$DATE.log"
    echo "" > "$LOG_FILE"
    /etc/init.d/log restart
fi
EOF
chmod +x /usr/bin/log_backup.sh

# Step 4: Create backup package script
# 建立每日打包所有備份檔案的腳本
cat <<'EOF' > /usr/bin/backup_pack.sh
#!/bin/sh
BACKUP_SOURCE="/root/backup"
BACKUP_TARGET="/root"
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="backup_$DATE.tar.gz"

[ -d "$BACKUP_SOURCE" ] || exit 1
cd "$BACKUP_SOURCE" || exit 1
tar -czf "$BACKUP_TARGET/$ARCHIVE_NAME" *
EOF
chmod +x /usr/bin/backup_pack.sh

# Step 5: Create old backup cleanup script
# 清理超過保存天數的打包備份檔案
cat <<'EOF' > /usr/bin/cleanup_old_backup.sh
#!/bin/sh
BACKUP_DIR="/root"
KEEP_DAYS=7
find "$BACKUP_DIR" -name "backup_*.tar.gz" -type f -mtime +$KEEP_DAYS -exec rm -f {} \;
EOF
chmod +x /usr/bin/cleanup_old_backup.sh

# Step 6: Create system health check script
# 每日檢查 overlay 空間與備份數量狀況
cat <<'EOF' > /usr/bin/system_health_check.sh
#!/bin/sh
OVERLAY_DIR="/overlay"
BACKUP_DIR="/root"
MAX_BACKUPS=50
DELETE_COUNT=10
THRESHOLD=10
DATE=$(date +%Y-%m-%d_%H:%M:%S)

FREE_PERCENT=$(df "$OVERLAY_DIR" | awk 'NR==2 {print $(NF-1)}' | tr -d '%')

logger -t system_health "[INFO] $DATE Overlay free space: $FREE_PERCENT%"

if [ "$FREE_PERCENT" -lt "$THRESHOLD" ]; then
    logger -t system_health "[WARN] $DATE Overlay disk space critically low ($FREE_PERCENT%)!"
fi

BACKUP_COUNT=$(ls -1 ${BACKUP_DIR}/backup_*.tar.gz 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    logger -t system_health "[WARN] $DATE Too many backup files ($BACKUP_COUNT), deleting oldest $DELETE_COUNT backups..."
    ls -1t ${BACKUP_DIR}/backup_*.tar.gz | tail -n $DELETE_COUNT | xargs rm -f
fi
EOF
chmod +x /usr/bin/system_health_check.sh

# Step 7: Create Docker log backup script
# 備份 docker container 的 log 文件
cat <<'EOF' > /usr/bin/backup_docker_log.sh
#!/bin/sh
DOCKER_LOG_DIR="/opt/docker/containers"
BACKUP_TARGET="/root/docker_log_backup"
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="docker_logs_$DATE.tar.gz"
KEEP_DAYS=7

mkdir -p "$BACKUP_TARGET"

find "$DOCKER_LOG_DIR" -name "*.log" | tar -czf "$BACKUP_TARGET/$ARCHIVE_NAME" -T -

find "$BACKUP_TARGET" -name "docker_logs_*.tar.gz" -type f -mtime +$KEEP_DAYS -exec rm -f {} \;
EOF
chmod +x /usr/bin/backup_docker_log.sh

# Step 8: Setup crontab tasks
# 將所有自動備份與監控任務加入 crontab
mkdir -p /etc/crontabs
echo "Updating crontab tasks..."
grep -q "/usr/bin/log_backup.sh" /etc/crontabs/root || echo "0 * * * * /usr/bin/log_backup.sh" >> /etc/crontabs/root
grep -q "mkdir -p /root/backup" /etc/crontabs/root || echo "0 3 * * * mkdir -p /root/backup/\$(date +\%Y\%m\%d) && cp -r /etc/* /root/backup/\$(date +\%Y\%m\%d)/" >> /etc/crontabs/root
grep -q "/usr/bin/backup_pack.sh" /etc/crontabs/root || echo "10 3 * * * /usr/bin/backup_pack.sh" >> /etc/crontabs/root
grep -q "/usr/bin/cleanup_old_backup.sh" /etc/crontabs/root || echo "20 3 * * * /usr/bin/cleanup_old_backup.sh" >> /etc/crontabs/root
grep -q "/usr/bin/system_health_check.sh" /etc/crontabs/root || echo "0 2 * * * /usr/bin/system_health_check.sh" >> /etc/crontabs/root
grep -q "/usr/bin/backup_docker_log.sh" /etc/crontabs/root || echo "30 1 * * * /usr/bin/backup_docker_log.sh" >> /etc/crontabs/root
grep -q "/usr/bin/system_watchdog.sh" /etc/crontabs/root || echo "*/10 * * * * /usr/bin/system_watchdog.sh" >> /etc/crontabs/root
grep -q "cron_reboot" /etc/crontabs/root || echo '0 4 1 * * logger -t cron_reboot "monthly reboot"; dmesg > /root/backup/dmesg_before_reboot_$(date +\%Y\%m\%d_\%H\%M).log; /usr/bin/log_backup.sh; /sbin/reboot' >> /etc/crontabs/root

# Step 9: Restart cron service
# 重啟 crontab 排程服務
echo "Restarting cron service..."
/etc/init.d/cron restart

# Step 10: Show current /overlay disk usage
# 顯示目前 overlay 區塊使用量
echo "===== Current /overlay Disk Usage ====="
df -h /overlay | awk 'NR==1 || NR==2'

# Step 11: Create watchdog script
# 建立 watchdog 腳本，當關鍵服務掛掉時觸發重啟並備份 dmesg 與 log
cat <<'EOF' > /usr/bin/system_watchdog.sh
#!/bin/sh

# 記錄 watchdog 腳本執行起始點
logger -t system_watchdog "Running system health check..."

# 若系統開機未滿 5 分鐘，跳過此次檢查，避免誤判服務尚未啟動
# Skip health check if system uptime is less than 5 minutes (e.g., just booted)
UPTIME_MIN=$(awk '{print int($1/60)}' /proc/uptime)
if [ "$UPTIME_MIN" -lt 5 ]; then
    logger -t system_watchdog "[INFO] Skipping health check - system just booted (${UPTIME_MIN} min)"
    exit 0
fi

# 檢查 Docker daemon 是否正在執行
if ! pgrep dockerd >/dev/null 2>&1; then
    logger -t system_watchdog "[ERROR] Docker daemon not running"
    RESTART_FLAG=1
fi

# 檢查 uhttpd (LuCI Web UI) 是否運行
# 檢查是否有程式監聽 port 80 以確認 HTTP/LuCI 服務是否啟動
# Check if port 80 is being listened to (indicating HTTP/LuCI service is up)
if ! netstat -tuln | grep -q ":80.*LISTEN"; then
    logger -t system_watchdog "[ERROR] No HTTP service (port 80) is listening"
    RESTART_FLAG=1
fi

FREE_MEM=$(free | grep Mem | awk '{print $4}')
LOAD_AVG=$(uptime | awk -F'load average: ' '{ print $2 }')
logger -t system_watchdog "Memory free: $FREE_MEM KB, Load: $LOAD_AVG"

if [ "$RESTART_FLAG" -eq 1 ]; then
    TS=$(date +%Y%m%d_%H%M%S)
    # 將核心訊息儲存起來以利重啟後調查
    dmesg > "/root/backup/dmesg_watchdog_before_reboot_${TS}.log"

    # 在 overlay log 保留 watchdog 觸發記錄
    echo "$TS: Reboot triggered due to service failure" >> /overlay/log/watchdog_reboot_history.log
    
    # 在系統 logger 中記錄此次重啟
    logger -t system_watchdog "[ACTION] Rebooting system due to service failure"
    
    # 備份當前 overlay 日誌
    /usr/bin/log_backup.sh

    # 執行正常重啟
    /sbin/reboot
    sleep 5

    # 若未成功，則強制重啟前再次備份
    logger -t system_watchdog "[WARN] Normal reboot failed, force rebooting now..."
    /usr/bin/log_backup.sh

    # 強制重啟
    exec /sbin/reboot -f
fi
EOF
chmod +x /usr/bin/system_watchdog.sh

# ===== Linxdot One-Key System Installer Completed =====
echo "===== Linxdot One-Key System Installer Completed ====="
