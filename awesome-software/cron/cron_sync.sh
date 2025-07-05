#!/bin/sh

# === OpenWrt 版 cron_sync.sh ===
# 從 GitHub 同步下來的 cron_reference 複製到系統 crontab 設定中，並重啟 cron。
# 注意：此版本不會備份舊的 crontab 設定，因為 GitHub 已有版本控制。

CRON_SRC="./cron_reference"
CRON_DST="/etc/crontabs/root"

# 檢查來源是否存在
if [ ! -f "$CRON_SRC" ]; then
  echo "[❌] 找不到 $CRON_SRC"
  exit 1
fi

# 複製新的 crontab 設定
cp "$CRON_SRC" "$CRON_DST"
chmod 600 "$CRON_DST"

# 重新啟動 cron 套用新設定
/etc/init.d/cron reload
/etc/init.d/cron restart

echo "[✅] crontab 已更新並套用"
echo "$(date): crontab updated from $CRON_SRC" >> /var/log/cron_sync.log