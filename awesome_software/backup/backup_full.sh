#!/bin/sh
# Linxdot / OpenWrt 多來源日誌備份腳本
# - 匯出 logread、dmesg、/var/log、/tmp/log、Docker 日誌（近 24h）
# - 產生壓縮檔並做保留輪替
# - 具備 overlay 磁區空間保護
# - 統一 log 輸出到 /var/log/backup_full.log

set -eu

#================= 可調整參數 =================
BACKUP_ROOT="/root/log_backup"
RETENTION_DAYS=14              # 保留幾天的備份檔
DOCKER_LOG_SINCE="24h"         # Docker 日誌截取時間範圍
FREE_THRESHOLD=10              # 視為「低容量」的閾值（%），低於時將跳過備份
LOGFILE="/var/log/backup_full.log"
#============================================

DATE_STR="$(date +%Y%m%d_%H%M%S)"
WORK_DIR="${BACKUP_ROOT}/${DATE_STR}"
ARCHIVE="${BACKUP_ROOT}/logs_${DATE_STR}.tar.gz"

# 判斷 overlay 掛載點（不同機型路徑略有差異）
if mount | grep -q "on / type overlay"; then
  OVERLAY_DIR="/"
else
  OVERLAY_DIR="/overlay"
fi

# 取得 overlay 使用率/剩餘率
USED_PCT="$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","");print $(NF-1)}')"
FREE_PCT=$((100 - USED_PCT))

mkdir -p "$BACKUP_ROOT"

log_info()  { logger -t "backup_logs_full" "[INFO] $*";  echo "[INFO] $*";  echo "[$(date '+%F %T')] [INFO] $*"  >> "$LOGFILE"; }
log_warn()  { logger -t "backup_logs_full" "[WARN] $*";  echo "[WARN] $*";  echo "[$(date '+%F %T')] [WARN] $*"  >> "$LOGFILE"; }
log_error() { logger -t "backup_logs_full" "[ERROR] $*"; echo "[ERROR] $*" 1>&2; echo "[$(date '+%F %T')] [ERROR] $*" >> "$LOGFILE"; }

log_info "Overlay free: ${FREE_PCT}% (used ${USED_PCT}%)"
if [ "$FREE_PCT" -lt "$FREE_THRESHOLD" ]; then
  log_warn "剩餘空間低於 ${FREE_THRESHOLD}%，跳過本次備份。"
  exit 0
fi

mkdir -p "$WORK_DIR"

#--- 系統基本資訊（方便排查） ---
{
  echo "==== uname -a ===="; uname -a
  echo
  echo "==== uptime ===="; uptime
  echo
  echo "==== df -h ===="; df -h
  echo
  echo "==== free -h ===="; free -h 2>/dev/null || free
  echo
  echo "==== ip addr ===="; ip addr 2>/dev/null || ifconfig -a 2>/dev/null || true
  echo
  echo "==== top (CPU/Memory snapshot) ===="; top -bn1 | head -20 2>/dev/null || true
} > "${WORK_DIR}/system_info.txt" 2>&1

#--- logread 匯出 ---
log_info "匯出 logread ..."
logread > "${WORK_DIR}/logread.txt" 2>&1 || true

#--- dmesg 匯出 ---
log_info "匯出 dmesg ..."
dmesg > "${WORK_DIR}/dmesg.txt" 2>&1 || true

#--- /var/log 與 /tmp/log（OpenWrt 多為 tmpfs）---
log_info "打包 /var/log 與 /tmp/log ..."
mkdir -p "${WORK_DIR}/var_tmp_log"
( tar -C / -czf "${WORK_DIR}/var_tmp_log/var_log.tgz" var/log 2>/dev/null ) || true
( tar -C / -czf "${WORK_DIR}/var_tmp_log/tmp_log.tgz" tmp/log 2>/dev/null ) || true

#--- Docker 日誌（可選）---
if command -v docker >/dev/null 2>&1; then
  log_info "收集 Docker 資訊與近 ${DOCKER_LOG_SINCE} 日誌 ..."
  DOCKER_DIR="${WORK_DIR}/docker"
  mkdir -p "$DOCKER_DIR"

  ( docker info && echo && docker system df && echo && docker images && echo && docker ps -a ) \
    > "${DOCKER_DIR}/docker_status.txt" 2>&1 || true

  docker ps -a --format '{{.ID}}|{{.Names}}' | while IFS="|" read -r ID NAME; do
    SAFE_NAME="$(echo "$NAME" | tr '/:' '__')"
    log_info "  匯出容器 ${NAME} 日誌 ..."
    docker logs --since "${DOCKER_LOG_SINCE}" "$ID" > "${DOCKER_DIR}/${SAFE_NAME}.log" 2>&1 || true
  done
else
  log_info "系統未安裝 docker，略過 Docker 日誌收集。"
fi

#--- 壓縮成單一檔案 ---
log_info "建立壓縮檔 ${ARCHIVE} ..."
if tar -czf "${ARCHIVE}" -C "${WORK_DIR}" .; then
  log_info "壓縮成功：${ARCHIVE}"
else
  log_error "壓縮失敗：${ARCHIVE}"
  rm -f "${ARCHIVE}"
  rm -rf "${WORK_DIR}"
  exit 1
fi

# 壓縮完成後刪除工作目錄
rm -rf "${WORK_DIR}"

#--- 清理過期備份 ---
log_info "清理超過 ${RETENTION_DAYS} 天的備份 ..."
OLD_FILES=$(find "${BACKUP_ROOT}" -type f -name "logs_*.tar.gz" -mtime +"${RETENTION_DAYS}")
COUNT=$(echo "$OLD_FILES" | grep -c . || true)

if [ "$COUNT" -gt 0 ]; then
  echo "$OLD_FILES" | while read -r f; do
    rm -f "$f" && log_info "  已刪除 ${f}"
  done
  log_info "清理完成，共刪除 ${COUNT} 個舊備份"
else
  log_info "沒有舊備份需要刪除"
fi

log_info "備份完成：${ARCHIVE}"
exit 0
