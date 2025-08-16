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
SCRIPT_DIR="/root/backup"
SUMMARY_LOG="/var/log/backup_summary.log"
LOCKFILE="/tmp/backup_run.lock"

DATE="$(date '+%F %T')"

# --- 測試模式 ---
if [ "$1" = "--test" ]; then
  echo "======================" >> "$SUMMARY_LOG"
  echo "[$DATE] Backup run started (TEST MODE)" >> "$SUMMARY_LOG"

  TEST_SCRIPT="${SCRIPT_DIR}/backup_test.sh"
  if [ -x "$TEST_SCRIPT" ]; then
    echo "[$DATE] Running backup_test.sh ..." >> "$SUMMARY_LOG"
    if "$TEST_SCRIPT" >> "$SUMMARY_LOG" 2>&1; then
      echo "[$DATE] ✅ backup_test.sh finished OK" >> "$SUMMARY_LOG"
    else
      echo "[$DATE] ❌ backup_test.sh failed (exit $?)" >> "$SUMMARY_LOG"
    fi
  else
    echo "[$DATE] ⚠️  backup_test.sh not found or not executable" >> "$SUMMARY_LOG"
  fi

  echo "[$DATE] Backup run completed (TEST MODE)" >> "$SUMMARY_LOG"
  echo "======================" >> "$SUMMARY_LOG"
  exit 0
fi

# --- 鎖機制 ---
if [ -e "$LOCKFILE" ]; then
  echo "[$DATE] WARN: another backup_run is already running" >> "$SUMMARY_LOG"
  exit 0
fi
touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT INT TERM

echo "======================" >> "$SUMMARY_LOG"
echo "[$DATE] Backup run started" >> "$SUMMARY_LOG"

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
    echo "[$DATE] Running $task ..." >> "$SUMMARY_LOG"
    if "$SCRIPT_PATH" >> "$SUMMARY_LOG" 2>&1; then
      echo "[$DATE] ✅ $task finished OK" >> "$SUMMARY_LOG"
    else
      echo "[$DATE] ❌ $task failed (exit $?)" >> "$SUMMARY_LOG"
    fi
  else
    echo "[$DATE] ⚠️  $task not found or not executable" >> "$SUMMARY_LOG"
  fi
done

echo "[$DATE] Backup run completed" >> "$SUMMARY_LOG"
echo "======================" >> "$SUMMARY_LOG"
