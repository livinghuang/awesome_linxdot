#!/bin/sh
###############################################################################
# Linxdot 系統備份監控與清理腳本
# 功能：
#   - 檢查 overlay 分區剩餘空間
#   - 若低於指定百分比 (THRESHOLD)，發出警告
#   - 若備份檔數量超過上限 (MAX_BACKUPS)，刪除最舊一批 (DELETE_BATCH)
#   - 適用於運行 OpenWrt 的裝置環境
###############################################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin

# === 參數設定 ===
BACKUP_DIR=/root              # 備份檔儲存路徑
MAX_BACKUPS=50                # 最大允許備份檔數量
DELETE_BATCH=10               # 超出後每次刪除幾筆
THRESHOLD=10                  # overlay 剩餘空間低於幾 % 就警告
DATE=$(date +%F_%T)           # 現在時間（格式：YYYY-MM-DD_HH:MM:SS）

# === 判斷 overlay 分區位置（根據 mount 結果判定）===
if mount | grep -q "on / type overlay"; then
  OVERLAY_DIR="/overlay"
else
  OVERLAY_DIR="/"
fi

# === 取得 overlay 分區使用率 ===
USED=$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","");print $(NF-1)}')
FREE=$((100 - USED))

# === log 當前磁碟空間狀況 ===
logger -t system_health "[INFO] $DATE Overlay free: ${FREE}% (used ${USED}%)"

# === 若剩餘空間低於門檻值，發出警告 ===
[ "$FREE" -lt "$THRESHOLD" ] && \
    logger -t system_health "[WARN] $DATE Disk free below ${THRESHOLD}%!"

# === 統計目前備份檔數量 ===
CNT=$(ls -1 "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | wc -l)

# === 若超過最大數量限制，刪除最舊一批 ===
if [ "$CNT" -gt "$MAX_BACKUPS" ]; then
  logger -t system_health "[WARN] $DATE Backup count ${CNT} > ${MAX_BACKUPS}, pruning ${DELETE_BATCH} old backups"
  ls -1t "$BACKUP_DIR"/backup_*.tar.gz | tail -n "$DELETE_BATCH" | xargs -r rm -f
fi
