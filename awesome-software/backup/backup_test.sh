#!/bin/sh
set -e
BASE_DIR="$(dirname "$0")"
LOG="/var/log/backup_test.log"
DATE=$(date +%Y%m%d)
START_TIME=$(date +%s)
ERROR_FLAG="/tmp/backup_failed.flag"

log() {
    echo "$(date '+%F %T') $1" | tee -a "$LOG"
}

warn() {
    echo "$(date '+%F %T') [WARN] $1" | tee -a "$LOG"
    touch "$ERROR_FLAG"
}

run_check() {
    SCRIPT="$1"
    DESC="$2"
    log "→ 開始執行：$DESC"
    if sh "$SCRIPT"; then
        log "✔ 成功：$DESC"
    else
        log "✘ 失敗：$DESC"
        touch "$ERROR_FLAG"
        exit 1
    fi
}

print_file_info() {
    FILE_PATH="$1"
    if [ -f "$FILE_PATH" ]; then
        SIZE=$(du -h "$FILE_PATH" | cut -f1)
        log "📦 檔案：$FILE_PATH（大小：$SIZE）"
    elif [ -d "$FILE_PATH" ]; then
        SIZE=$(du -sh "$FILE_PATH" | cut -f1)
        log "📁 目錄：$FILE_PATH（大小：$SIZE）"
    else
        warn "$FILE_PATH 不存在或無法存取"
    fi
}

log "===== 備份測試流程開始 ====="
rm -f "$ERROR_FLAG"

run_check "$BASE_DIR/backup_log.sh" "備份系統 log"
LOGFILE=$(ls -t /root/backup/messages_${DATE}*.log 2>/dev/null | head -n1)
[ -n "$LOGFILE" ] && print_file_info "$LOGFILE" || warn "系統 log 檔不存在"

run_check "$BASE_DIR/backup_docker_log.sh" "備份 Docker log"
DOCKERFILE=$(ls -t /root/docker_log_backup/docker_logs_${DATE}*.tar.gz 2>/dev/null | head -n1)
[ -n "$DOCKERFILE" ] && print_file_info "$DOCKERFILE" || warn "Docker log 檔不存在"

run_check "$BASE_DIR/backup_etc.sh" "備份 /etc 設定"
ETCDIR=$(ls -dt /root/backup/etc_${DATE}* 2>/dev/null | head -n1)
[ -n "$ETCDIR" ] && print_file_info "$ETCDIR" || warn "/etc 備份資料夾不存在"

run_check "$BASE_DIR/backup_pack.sh" "打包所有備份"
PACKFILE=$(ls -t /root/backup_${DATE}*.tar.gz 2>/dev/null | head -n1)
[ -n "$PACKFILE" ] && print_file_info "$PACKFILE" || warn "打包檔案不存在"

run_check "$BASE_DIR/backup_clean_old_record.sh" "清理過期備份"

# 顯示目前備份總空間
TOTAL_BACKUP_SIZE=$(du -sh /root/backup 2>/dev/null | cut -f1)
log "📊 /root/backup 使用空間總計：$TOTAL_BACKUP_SIZE"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
log "===== 備份測試流程完成，用時 ${DURATION} 秒 ====="

# 顯示結果狀態
if [ -f "$ERROR_FLAG" ]; then
    warn "🚨 備份測試發現問題，請檢查 log：$LOG"
else
    log "✅ 備份測試全部成功"
fi
