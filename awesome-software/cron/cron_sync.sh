#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRON_SRC="$SCRIPT_DIR/cron_reference"
CRON_DST="/etc/crontabs/root"
LOG_FILE="/var/log/cron_sync.log"

if [ ! -f "$CRON_SRC" ]; then
  echo "[❌] 找不到 cron_reference：$CRON_SRC"
  logger -t cron_sync "[FAIL] Missing cron_reference"
  exit 1
fi

cp "$CRON_SRC" "$CRON_DST"
chmod 600 "$CRON_DST"
chown root:root "$CRON_DST"

# 更保守地重啟 cron，避免 restart 卡住
killall crond 2>/dev/null
sleep 1
/etc/init.d/cron start

NOW="$(date '+%Y-%m-%d %H:%M:%S')"
echo "[$NOW] ✅ crontab 已更新並重啟 cron" >> "$LOG_FILE"
logger -t cron_sync "[OK] crontab updated from $CRON_SRC"
