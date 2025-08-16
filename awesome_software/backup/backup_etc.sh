#!/bin/sh
###############################################################################
# /etc 設定備份腳本
# 功能：
#   - 備份目前整個 /etc 設定資料夾內容到 /root/backup/etc_時間戳目錄
#   - 保留最近 7 天，刪除更舊的
#   - 紀錄操作過程到 /var/log/backup_etc.log
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin
DATE=$(date +%Y%m%d_%H%M%S)
DIR="/root/backup/etc_$DATE"
LOGFILE="/var/log/backup_etc.log"

# 建立目標備份目錄
mkdir -p "$DIR"

# 備份 /etc 下所有內容（含隱藏檔，保留權限與符號連結）
cp -a /etc/* "$DIR/"
cp -a /etc/.* "$DIR/" 2>/dev/null || true

echo "[$(date '+%F %T')] Backup etc -> $DIR" >> "$LOGFILE"

# 清理 7 天前的備份
find /root/backup -maxdepth 1 -type d -name "etc_*" -mtime +7 | while read f; do
  echo "[$(date '+%F %T')] Deleted old etc backup: $f" >> "$LOGFILE"
  rm -rf "$f"
done
