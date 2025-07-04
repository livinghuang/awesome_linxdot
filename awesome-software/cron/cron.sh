#!/bin/sh

# === OpenWrt 版 cron.sh ===
CRON_SRC="./cron_reference"
CRON_DST="/etc/crontabs/root"
BACKUP_DIR="/etc/crontabs/backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# === 確保來源存在 ===
if [ ! -f "$CRON_SRC" ]; then
  echo "[❌] 找不到 $CRON_SRC"
  exit 1
fi

# === 備份舊的 cron 設定 ===
mkdir -p "$BACKUP_DIR"
[ -f "$CRON_DST" ] && cp "$CRON_DST" "$BACKUP_DIR/root_$TIMESTAMP"

# === 複製新設定 ===
cp "$CRON_SRC" "$CRON_DST"
chmod 600 "$CRON_DST"

# === 重新啟用 crontab ===
/etc/init.d/cron reload
/etc/init.d/cron restart

echo "[✅] crontab 已更新並套用，備份存在 $BACKUP_DIR"
