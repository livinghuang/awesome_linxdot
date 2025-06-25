#!/bin/sh
###############################################################################
# Linxdot One‑Key System Installer – *annotated version*
#
# 這支腳本在第一次開機或重置時一次完成：
#   1. 建立 overlay 持久化日誌目錄並設定 logd
#   2. 安裝 7 支維運腳本到 /usr/share/linxdot，再以 symlink 暴露在 /usr/bin
#   3. 設定 crontab 任務 (log 備份 / 健康檢查 / Docker log / Watchdog …)
#   4. 寫入版本檔 /etc/linxdot_installer.version 方便 OTA 判別
#
# 2025‑06‑24 版本（v2025.06.24）
###############################################################################
set -e

VERSION="2025.06.24"
echo "===== Linxdot One-Key System Installer v$VERSION Start ====="

LOG_DIR=/overlay/log
LOG_FILE="$LOG_DIR/messages"
LOG_SIZE=512
BACKUP_DIR=/root/backup
MAX_BACKUPS=50
DELETE_BATCH=10
THRESHOLD=20
KEEP_DAYS=7
CRON_FILE=/etc/crontabs/root
INSTALL_BASE=/usr/share/linxdot
PATH=/bin:/sbin:/usr/bin:/usr/sbin

mkdir -p "$LOG_DIR" "$INSTALL_BASE"
chmod 755 "$LOG_DIR"

uci batch <<EOF
set system.@system[0].log_file='$LOG_FILE'
set system.@system[0].log_size='$LOG_SIZE'
commit system
EOF
/etc/init.d/log restart
printf 'logd configured to %s (%s KiB)\n' "$LOG_FILE" "$LOG_SIZE"

install_script() {
  name="$1"; shift
  printf '%s\n' "$@" > "$INSTALL_BASE/$name.sh"
  chmod +x "$INSTALL_BASE/$name.sh"
  ln -sf "$INSTALL_BASE/$name.sh" "/usr/bin/$name.sh"
}

# log_backup.sh
install_script log_backup \
  '#!/bin/sh' \
  'PATH=/bin:/sbin:/usr/bin:/usr/sbin' \
  'LOG_FILE="/overlay/log/messages"' \
  'BACKUP_DIR="/root/backup"' \
  'DATE=$(date +%Y%m%d_%H%M%S)' \
  'OVERLAY_DIR=$(mount | awk '\''$3=="/overlay"{print $3}'\'')' \
  '[ -z "$OVERLAY_DIR" ] && OVERLAY_DIR="/"' \
  'USED=$(df "$OVERLAY_DIR" | awk '\''NR==2{gsub("%","");print $(NF-1)}'\'')' \
  'FREE=$((100-USED))' \
  '[ "$FREE" -lt 5 ] && logger -t log_backup "[WARN] Low disk space ($FREE%)" && \
    ls -1t "$BACKUP_DIR"/messages_*.log 2>/dev/null | tail -n 1 | xargs -r rm -f' \
  'mkdir -p "$BACKUP_DIR"' \
  '[ -f "$LOG_FILE" ] && cp "$LOG_FILE" "$BACKUP_DIR/messages_$DATE.log" && : > "$LOG_FILE"' \
  '/etc/init.d/log restart'

# backup_pack.sh
install_script backup_pack \
  '#!/bin/sh' \
  'PATH=/bin:/sbin:/usr/bin:/usr/sbin' \
  'SRC=/root/backup' \
  'DST=/root' \
  'DATE=$(date +%Y%m%d_%H%M%S)' \
  '[ -d "$SRC" ] || exit 0' \
  'tar -C "$SRC" -czf "$DST/backup_$DATE.tar.gz" .'

# cleanup_old_backup.sh
install_script cleanup_old_backup \
  '#!/bin/sh' \
  'PATH=/bin:/sbin:/usr/bin:/usr/sbin' \
  "KEEP_DAYS=${KEEP_DAYS:-7}" \
  'find /root              -name "backup_*.tar.gz"      -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;' \
  'find /root/backup       -name "messages_*.log"       -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;' \
  'find /root/docker_log_backup -name "docker_logs_*.tar.gz" -type f -mtime +"$KEEP_DAYS" -exec rm -f {} \;'

# system_health_check.sh
install_script system_health_check \
  '#!/bin/sh' \
  'PATH=/bin:/sbin:/usr/bin:/usr/sbin' \
  'BACKUP_DIR=/root' \
  'MAX_BACKUPS=50' \
  'DELETE_BATCH=10' \
  'THRESHOLD=10' \
  'DATE=$(date +%F_%T)' \
  'if mount | grep -q "on / type overlay"; then' \
  '  OVERLAY_DIR="/overlay"' \
  'else' \
  '  OVERLAY_DIR="/"' \
  'fi' \
  'USED=$(df "$OVERLAY_DIR" | awk '\''NR==2{gsub("%","");print $(NF-1)}'\'')' \
  'FREE=$((100-USED))' \
  'logger -t system_health "[INFO] $DATE Overlay free: ${FREE}% (used ${USED}%)"' \
  '[ "$FREE" -lt "$THRESHOLD" ] && logger -t system_health "[WARN] $DATE Disk free below ${THRESHOLD}%!"' \
  'CNT=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)' \
  '[ "$CNT" -gt "$MAX_BACKUPS" ] && {' \
  '  logger -t system_health "[WARN] $DATE Backup count ${CNT} > ${MAX_BACKUPS}, prune ${DELETE_BATCH}"' \
  '  ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n "$DELETE_BATCH" | xargs -r rm -f' \
  '}'

# backup_docker_log.sh
install_script backup_docker_log \
  '#!/bin/sh' \
  'PATH=/bin:/sbin:/usr/bin:/usr/sbin' \
  'SRC=/opt/docker/containers' \
  'DST=/root/docker_log_backup' \
  'DATE=$(date +%Y%m%d_%H%M%S)' \
  'KEEP=7' \
  'mkdir -p "$DST"' \
  'find "$SRC" -name "*.log" -print0 | tar --null -czf "$DST/docker_logs_$DATE.tar.gz" --files-from=-' \
  'find "$DST" -name "docker_logs_*.tar.gz" -mtime +$KEEP -exec rm -f {} \;'

# system_watchdog.sh
install_script system_watchdog \
  '#!/bin/sh' \
  'PATH=/bin:/sbin:/usr/bin:/usr/sbin' \
  '[ $(awk '\''{print int($1/60)}'\'' /proc/uptime) -lt 5 ] && exit 0' \
  'REBOOT=0' \
  'pgrep dockerd >/dev/null 2>&1 || { logger -t watchdog "[ERR] dockerd down"; REBOOT=1; }' \
  'netstat -tln | grep -q ":80 .*LISTEN" || { logger -t watchdog "[ERR] no http server"; REBOOT=1; }' \
  '[ "$REBOOT" -eq 1 ] && {' \
  '  dmesg > /root/backup/dmesg_watchdog_$(date +%F_%H-%M-%S).log' \
  '  /usr/bin/log_backup.sh' \
  '  sleep 5' \
  '  logger -t watchdog "[ACTION] rebooting…"' \
  '  reboot' \
  '}'

# backup_etc.sh
install_script backup_etc \
  '#!/bin/sh' \
  'DATE=$(date +%Y%m%d_%H%M%S)' \
  'DIR="/root/backup/etc_$DATE"' \
  'mkdir -p "$DIR"' \
  'cp -r /etc/* "$DIR/"'

: > "$CRON_FILE"
cat >> "$CRON_FILE" <<'EOF'
SHELL=/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin
0   * * * * /usr/bin/log_backup.sh
0   3 * * * /usr/bin/backup_etc.sh
10  3 * * * /usr/bin/backup_pack.sh
20  3 * * * /usr/bin/cleanup_old_backup.sh
0   2 * * * /usr/bin/system_health_check.sh
30  1 * * * /usr/bin/backup_docker_log.sh
*/10 * * * * /usr/bin/system_watchdog.sh
EOF

/etc/init.d/cron restart
printf 'Cron reloaded.\n'

echo '===== Current disk usage ====='
df -h | awk 'NR==1 || $6=="/" || $6=="/overlay"'

echo "$VERSION" > /etc/linxdot_installer.version
printf '===== Linxdot One-Key System Installer Completed =====\n'
###############################################################################
