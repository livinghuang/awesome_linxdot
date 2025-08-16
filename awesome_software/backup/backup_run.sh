#!/bin/sh
###############################################################################
# Linxdot Backup Run Script
# 功能：
#   - 統一呼叫所有子備份腳本（依建議順序）
#   - 支援 --test 模式，只執行 backup_test.sh
#   - 將輸出集中到 summary log
#   - 鎖機制避免重複執行
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
SCRIPT_DIR="/opt/awesome_linxdot/awesome_software/backup"
SUMMARY_LOG="/var/log/backup_summary.log"
LOCKFILE="/tmp/backup_run.lock"
DATE="$(date '+%F %T')"

log() {
  echo "[$(date '+%F %T')] $*" >> "$SUMMARY_LOG"
}

# --- 測試模式 ---
if [ "$1" = "--test" ]; then
  {
    echo "======================"
    log "Backup run started (TEST MODE)"
  } >> "$SUMMARY_LOG"

  TEST_SCRIPT="${SCRIPT_DIR}/backup_test.sh"
  if [ -x "$TEST_SCRIPT" ]; then
    log "Running backup_test.sh ..."
    if "$TEST_SCRIPT" >> "$SUMMARY_LOG" 2>&1; then
      log "✅ backup_test.sh finished OK"
    else
      rc=$?
      log "❌ backup_test.sh failed (exit $rc)"
    fi
  else
    log "⚠️  backup_test.sh not found or not executable"
  fi

  log "Backup run completed (TEST MODE)"
  echo "======================" >> "$SUMMARY_LOG"
  exit 0
fi

# --- 鎖機制 ---
if [ -e "$LOCKFILE" ]; then
  if kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
    log "WARN: another backup_run is already running (PID $(cat "$LOCKFILE"))"
    exit 0
  else
    log "Stale lock detected, removing"
    rm -f "$LOCKFILE"
  fi
fi

echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT INT TERM

{
  echo "======================"
  log "Backup run started"
} >> "$SUMMARY_LOG"

# --- 建議執行順序 ---
TASKS="
backup_syslog.sh
backup_docker.sh
backup_etc.sh
backup_full.sh
backup_pack.sh
backup_clean_old_record.sh
"

# --- 執行 ---
for task in $TASKS; do
  SCRIPT_PATH="${SCRIPT_DIR}/${task}"
  if [ -x "$SCRIPT_PATH" ]; then
    log "Running $task ..."
    if "$SCRIPT_PATH" >> "$SUMMARY_LOG" 2>&1; then
      log "✅ $task finished OK"
    else
      rc=$?
      log "❌ $task failed (exit $rc)"
    fi
  else
    log "⚠️  $task not found or not executable"
  fi
done

log "Backup run completed"
echo "======================" >> "$SUMMARY_LOG"
