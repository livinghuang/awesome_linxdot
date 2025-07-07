#!/bin/sh

# === Linxdot OpenWrt 專用：crontab 自動同步腳本 ===
# 作者：Living Huang
# 版本：v2.3
# 功能：
# - 從 GitHub 同步下來的 cron_reference 自動套用到系統 crontab
# - 若內容無變化，則跳過套用與重啟，避免不必要的操作
# - 若有變更，則會自動複製並安全地重啟 cron
# - 寫入 log 檔與 logger（系統 logread 可查）
# 適用場景：
# - 大量裝置 OTA 管理
# - 避免誤觸 @reboot 任務
# - Linxdot 自我修復 crontab 策略

# === 設定檔案路徑 ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"              # 取得本腳本所在目錄絕對路徑
CRON_SRC="$SCRIPT_DIR/cron_reference"                    # 來源：版本控制的排程檔
CRON_DST="/etc/crontabs/root"                            # 目標：OpenWrt 實際使用的 crontab 檔案
LOG_FILE="/var/log/cron_sync.log"                        # 本腳本操作 log（供追蹤用）

# === 1. 檢查來源檔案是否存在 ===
if [ ! -f "$CRON_SRC" ]; then
  echo "[❌] 找不到 cron_reference：$CRON_SRC"
  logger -t cron_sync "[FAIL] Missing cron_reference"
  exit 1
fi

# === 2. 檢查是否有實際內容變化 ===
# 如果兩個檔案內容一樣，就略過後續步驟，避免冗餘重啟 cron
if cmp -s "$CRON_SRC" "$CRON_DST"; then
  echo "[$(date)] ⚠️ crontab 無變更，略過套用與重啟" >> "$LOG_FILE"
  logger -t cron_sync "[SKIP] crontab not changed"
  exit 0
fi

# === 3. 複製新的 crontab 設定 ===
cp "$CRON_SRC" "$CRON_DST"                               # 覆蓋系統 crontab
chmod 600 "$CRON_DST"                                    # 設定檔案權限
chown root:root "$CRON_DST"                              # 確保擁有者為 root（有些系統會出錯）

# === 4. 安全重啟 cron（比 restart 更保守）===
# 若使用 restart，在某些 BusyBox 環境下可能會卡住 → 改用 kill + start 更穩定
killall crond 2>/dev/null                                # 若 crond 已存在則關閉
sleep 1                                                  # 等待 1 秒避免殘留 zombie
/etc/init.d/cron start                                   # 再次啟動 crond

# === 5. 寫入更新紀錄到 log 與 syslog ===
NOW="$(date '+%Y-%m-%d %H:%M:%S')"                       # 時間戳記
echo "[$NOW] ✅ crontab 已更新並重啟 cron" >> "$LOG_FILE"
logger -t cron_sync "[OK] crontab updated from $CRON_SRC"
