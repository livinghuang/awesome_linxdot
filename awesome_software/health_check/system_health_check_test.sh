#!/bin/sh
###############################################################################
# 測試用腳本：system_health_check.sh
# 功能：
#   - 執行 system_health_check.sh 並顯示前後變化
#   - 列出備份檔數、overlay 空間狀態
#   - 若有檔案刪除則列出清單
###############################################################################

set -e
BASE_DIR="$(dirname "$0")"
CHECK_SCRIPT="$BASE_DIR/system_health_check.sh"
BACKUP_DIR="/root"
TMP_BEFORE="/tmp/backup_before.txt"
TMP_AFTER="/tmp/backup_after.txt"

echo "📦 備份健康檢查測試開始"

# 取得執行前備份清單
ls -1t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null > "$TMP_BEFORE" || touch "$TMP_BEFORE"
CNT_BEFORE=$(cat "$TMP_BEFORE" | wc -l)

# 顯示 overlay 使用狀態
echo "🧠 overlay 使用狀態："
df /overlay 2>/dev/null || df /

# 執行檢查腳本
echo "🚀 執行 system_health_check.sh..."
sh "$CHECK_SCRIPT"

# 取得執行後備份清單
ls -1t "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null > "$TMP_AFTER" || touch "$TMP_AFTER"
CNT_AFTER=$(cat "$TMP_AFTER" | wc -l)

# 顯示備份數變化
echo "🧾 備份檔數：執行前 $CNT_BEFORE 個 → 執行後 $CNT_AFTER 個"

# 顯示有無被刪除的檔案
echo "📉 被刪除的檔案（如有）："
comm -23 "$TMP_BEFORE" "$TMP_AFTER" || echo "無"

# 顯示 log 記錄摘要
echo "📝 最新 system_health log 訊息："
logread | grep system_health | tail -n 10 || echo "(無訊息)"

echo "✅ system_health 測試結束"
