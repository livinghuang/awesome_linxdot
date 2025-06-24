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
set -e  # ➜ 任一指令失敗即中止，避免半套安裝

VERSION="2025.06.24"
echo "===== Linxdot One-Key System Installer v$VERSION Start ====="

# -----------------------------------------------------------------------------
# 0. 參數區 – 需要調整只改這裡
# -----------------------------------------------------------------------------
LOG_DIR=/overlay/log              # 日誌目錄 (overlay)
LOG_FILE="$LOG_DIR/messages"      # logd 寫入檔
LOG_SIZE=512                      # KiB，BusyBox logd 上限
BACKUP_DIR=/root/backup           # 所有備份存放根目錄
MAX_BACKUPS=50                    # 最多保留幾個 backup_*.tar.gz
DELETE_BATCH=10                   # 超量一次刪幾個
THRESHOLD=20                      # 剩餘空間 < 20% 就警告
KEEP_DAYS=7                       # .tar.gz 保留天數
CRON_FILE=/etc/crontabs/root      # root crontab
INSTALL_BASE=/usr/share/linxdot   # 所有腳本本體存放處
PATH=/bin:/sbin:/usr/bin:/usr/sbin

# -----------------------------------------------------------------------------
# 1. 建立必要目錄
# -----------------------------------------------------------------------------
mkdir -p "$LOG_DIR" "$INSTALL_BASE"
chmod 755 "$LOG_DIR"  # overlay/log 需可讀寫

# -----------------------------------------------------------------------------
# 2. 設定 logd 讓系統日誌持久化
# -----------------------------------------------------------------------------
uci batch <<EOF
set system.@system[0].log_file='$LOG_FILE'
set system.@system[0].log_size='$LOG_SIZE'
commit system
EOF
/etc/init.d/log restart
printf 'logd configured to %s (%s KiB)\n' "$LOG_FILE" "$LOG_SIZE"

# -----------------------------------------------------------------------------
# 3. install_script() – 動態產生腳本 + symlink
# -----------------------------------------------------------------------------
# 用法： install_script <name_without_ext> '\n<真正 script 內容>\n'
#
# ➜ 內容以 printf '%s\n' 寫入，避免 EOF/quote 陷阱
install_script() {
  name="$1"; shift
  printf '%s\n' "$@" > "$INSTALL_BASE/$name.sh"
  chmod +x "$INSTALL_BASE/$name.sh"
  ln -sf "$INSTALL_BASE/$name.sh" "/usr/bin/$name.sh"
}

# --- log_backup.sh (每小時備份 overlay/messages → /root/backup) -------------
install_script log_backup '\n#!/bin/sh\nPATH=/bin:/sbin:/usr/bin:/usr/sbin\nLOG_FILE="/overlay/log/messages"\nBACKUP_DIR="/root/backup"\nDATE=$(date +%Y%m%d_%H%M%S)\nOVERLAY_DIR=$(mount | awk '\''$3=="/overlay"{print $3}'\'')\n[ -z "$OVERLAY_DIR" ] && OVERLAY_DIR="/"\nUSED=$(df "$OVERLAY_DIR" | awk '\''NR==2{gsub("%","");print $(NF-1)}'\'')\nFREE=$((100-USED))\n[ "$FREE" -lt 5 ] && logger -t log_backup "[WARN] Low disk space ($FREE%)" && \
  ls -1t "$BACKUP_DIR"/messages_*.log 2>/dev/null | tail -n 1 | xargs -r rm -f\nmkdir -p "$BACKUP_DIR"\n[ -f "$LOG_FILE" ] && cp "$LOG_FILE" "$BACKUP_DIR/messages_$DATE.log" && : > "$LOG_FILE"\n/etc/init.d/log restart\n'

# --- backup_pack.sh (03:10 打包 /root/backup) --------------------------------
install_script backup_pack '\n#!/bin/sh\nPATH=/bin:/sbin:/usr/bin:/usr/sbin\nSRC=/root/backup\nDST=/root\nDATE=$(date +%Y%m%d_%H%M%S)\n[ -d "$SRC" ] || exit 0\ntar -C "$SRC" -czf "$DST/backup_$DATE.tar.gz" .\n'

# --- cleanup_old_backup.sh (03:20 清理舊 .tar.gz) ----------------------------
install_script cleanup_old_backup "\n#!/bin/sh\nfind /root -name 'backup_*.tar.gz' -type f -mtime +$KEEP_DAYS -delete\n"

# --- system_health_check.sh (02:00 健康檢查) ----------------------------------
install_script system_health_check '\n#!/bin/sh\nPATH=/bin:/sbin:/usr/bin:/usr/sbin\nBACKUP_DIR=/root\nMAX_BACKUPS=50\nDELETE_BATCH=10\nTHRESHOLD=10\nDATE=$(date +%F_%T)\n# --- 判斷 overlay or / -----------------------------\nif mount | grep -q "on / type overlay"; then\n  OVERLAY_DIR="/overlay"\nelse\n  OVERLAY_DIR="/"\nfi\nUSED=$(df "$OVERLAY_DIR" | awk '\''NR==2{gsub("%","");print $(NF-1)}'\'')\nFREE=$((100-USED))\nlogger -t system_health "[INFO] $DATE Overlay free: ${FREE}% (used ${USED}%)"\n[ "$FREE" -lt "$THRESHOLD" ] && logger -t system_health "[WARN] $DATE Disk free below ${THRESHOLD}%!"\nCNT=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)\nif [ "$CNT" -gt "$MAX_BACKUPS" ]; then\n  logger -t system_health "[WARN] $DATE Backup count ${CNT} > ${MAX_BACKUPS}, prune ${DELETE_BATCH}"\n  ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n "$DELETE_BATCH" | xargs -r rm -f\nfi\n'

# --- backup_docker_log.sh (01:30 備份 Docker container log) -------------------
install_script backup_docker_log '\n#!/bin/sh\nPATH=/bin:/sbin:/usr/bin:/usr/sbin\nSRC=/opt/docker/containers\nDST=/root/docker_log_backup\nDATE=$(date +%Y%m%d_%H%M%S)\nKEEP=7\nmkdir -p "$DST"\nfind "$SRC" -name "*.log" -print0 | tar --null -czf "$DST/docker_logs_$DATE.tar.gz" --files-from=-\nfind "$DST" -name "docker_logs_*.tar.gz" -mtime +$KEEP -delete\n'

# --- system_watchdog.sh (每 10 分自檢 Dockerd / HTTP) -------------------------
install_script system_watchdog '\n#!/bin/sh\nPATH=/bin:/sbin:/usr/bin:/usr/sbin\n[ $(awk '\''{print int($1/60)}'\'' /proc/uptime) -lt 5 ] && exit 0\nREBOOT=0\npgrep dockerd >/dev/null 2>&1 || { logger -t watchdog "[ERR] dockerd down"; REBOOT=1; }\nnetstat -tln | grep -q ":80 .*LISTEN" || { logger -t watchdog "[ERR] no http server"; REBOOT=1; }\nif [ "$REBOOT" -eq 1 ]; then\n  dmesg > /root/backup/dmesg_watchdog_$(date +%F_%H-%M-%S).log\n  /usr/bin/log_backup.sh\n  sleep 5\n  logger -t watchdog "[ACTION] rebooting…"\n  reboot\nfi\n'

# --- backup_etc.sh (03:00 備份 /etc) -----------------------------------------
install_script backup_etc '\n#!/bin/sh\nDATE=$(date +%Y%m%d_%H%M%S)\nDIR="/root/backup/etc_$DATE"\nmkdir -p "$DIR"\ncp -r /etc/* "$DIR/"\n'

# -----------------------------------------------------------------------------
# 4. crontab 排程 – 重新寫入
# -----------------------------------------------------------------------------
: > "$CRON_FILE"  # 清空現有 crontab
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

# -----------------------------------------------------------------------------
# 5. 顯示系統資訊
# -----------------------------------------------------------------------------
printf '===== Current disk usage =====\n'
df -h | awk 'NR==1 || $6=="/" || $6=="/overlay"'

# -----------------------------------------------------------------------------
# 6. 完成
# -----------------------------------------------------------------------------
echo "$VERSION" > /etc/linxdot_installer.version
printf '===== Linxdot One-Key System Installer Completed =====\n'
###############################################################################
