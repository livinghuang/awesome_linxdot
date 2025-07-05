#!/bin/sh

# === OpenWrt 版 cron_sync.sh v2 ===
# 從 GitHub 同步的 cron_reference 套用為系統 crontab，並重啟 cron。
# 無備份（版本由 Git 控）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRON_SRC="$SCRIPT_DIR/cron_reference"
CRON_DST="/etc/crontabs/root"
LOG_FILE="/var/log/cron_sync.log"

# 檢查來源檔案是否存在
if [ ! -f "$CRON_SRC" ]; then
  echo "[❌] 找不到 cron_reference：$CRON_SRC"
  logger -t cron_sync "[FAIL] Missing cron_reference"
  exit 1
fi

# 複製新的 crontab 設定
cp "$CRON_SRC" "$CRON_DST"
chmod 600 "$CRON_DST"

# 重新啟動 cron
/etc/init.d/cron reload
/etc/init.d/cron restart

# Log 紀錄
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
echo "[$NOW] ✅ crontab 已更新：$CRON_SRC → $CRON_DST" >> "$LOG_FILE"
logger -t cron_sync "[OK] crontab updated from $CRON_SRC"
