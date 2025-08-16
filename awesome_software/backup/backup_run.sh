#!/bin/sh
###############################################################################
# Linxdot Backup Run Script
# - Orchestrates all sub-scripts in a safe order
# - Supports --test (runs backup_test.sh only)
# - Writes a summary log and prevents concurrent runs (PID lock)
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Resolve script directory (absolute), BusyBox friendly
SCRIPT_DIR="$(dirname "$0")"
case "$SCRIPT_DIR" in
  /*) : ;;
  *) SCRIPT_DIR="$(pwd)/$SCRIPT_DIR" ;;
esac

SUMMARY_LOG="/var/log/backup_summary.log"
LOCKFILE="/tmp/backup_run.lock"

log() { echo "[$(date '+%F %T')] $*" >> "$SUMMARY_LOG"; }

# --test mode ---------------------------------------------------------------
if [ "${1:-}" = "--test" ]; then
  echo "======================" >> "$SUMMARY_LOG"
  log "Backup run started (TEST MODE)"

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

# Locking (PID-based) -------------------------------------------------------
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

echo "======================" >> "$SUMMARY_LOG"
log "Backup run started"

# Order matters: free space first, then heavy tasks, then packing and sweeping.
TASKS="
backup_syslog.sh
backup_docker.sh
backup_etc.sh
backup_full.sh
backup_pack.sh
backup_clean_old_record.sh
"

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
