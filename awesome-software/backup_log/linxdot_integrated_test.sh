#!/bin/sh
###############################################################################
# Linxdot 綜合自動測試腳本 (cron 觸發 + 低空間清理)
###############################################################################
set -e

# --- 可調整參數 -------------------------------------------------------------
NTP_SERVICE="sysntpd"           # NTP 背景服務名稱（OpenWrt 預設）
START_DAY="2000-01-01"          # 測試起始日期
END_DAY="2000-01-09"            # 測試結束日期
TIMES="01:30:00 02:00:00 03:00:00 03:10:00 03:20:00"  # 每天模擬時間點
SLEEP_SEC=61                     # 每次等待 cron 觸發秒數
FILL_THRESHOLD=10                # 模擬剩餘空間低於 10%%
FILL_STEP_MB=2800                # 每次填充約 10%% 容量（視實際容量調整）
LOWER_MB_LIMIT=1500             # 最少保留 1.5 GB
OVERLAY_DIR="/"                 # 改為填充根目錄
FILL_FILE="$OVERLAY_DIR/fill.bin"

###############################################################################
# 0. 停用 NTP & 備份原始系統時間
###############################################################################
ORIGINAL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "📌 原始系統時間：$ORIGINAL_DATE"

if /etc/init.d/$NTP_SERVICE status >/dev/null 2>&1; then
  echo "⏸️  停用 $NTP_SERVICE …";
  /etc/init.d/$NTP_SERVICE stop || true
else
  echo "⚠️  找不到 $NTP_SERVICE，略過停用。"
fi

###############################################################################
# 1. 逐日逐時模擬 → 驗證 cron 觸發
###############################################################################
start_ts=$(date -d "$START_DAY" +%s)
end_ts=$(date -d "$END_DAY" +%s)

while [ "$start_ts" -le "$end_ts" ]; do
  day=$(date -d "@$start_ts" +%Y-%m-%d)
  echo "\n🗓 測試日期：$day"
  for t in $TIMES; do
    sim_time="$day $t"
    echo " → 模擬系統時間：$sim_time"
    date -s "$sim_time" >/dev/null
    echo "    等待 crond 觸發… ($SLEEP_SEC 秒)"
    for _ in $(seq 1 $SLEEP_SEC); do printf "."; sleep 1; done; echo " ✅"

    echo "    ⤵ /root 當前內容（時間排序）："
    ls -lhtr /root || echo "⚠️ 無法讀取 /root 內容"

    echo "    ⤵ /root/backup 當前內容（時間排序）："
    ls -lhtr /root/backup | tail || echo "⚠️ 無法讀取 /root/backup 內容"

    echo "    🧾 cron log 檢查（messages 最後 10 行）："
    tail -n 10 /overlay/log/messages | grep -Ei 'backup|system_health' || echo "    ⚠️ 沒有發現備份相關記錄"
  done
  start_ts=$((start_ts + 86400))
done

###############################################################################
# 2. 模擬磁碟空間不足 (<10%) 或剩餘 <1.5 GB)
###############################################################################
echo "\n🚨 [低空間測試] 填充 $OVERLAY_DIR，直到剩餘 < ${FILL_THRESHOLD}% 或 < ${LOWER_MB_LIMIT}MB…"
while : ; do
  USED=$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","");print $(NF-1)}')
  FREE_MB=$(df "$OVERLAY_DIR" | awk 'NR==2{print $(NF-2)}')
  [ "$USED" -ge $((100 - FILL_THRESHOLD)) ] && { echo "✅ 已達 ${USED}% 使用率"; break; }
  [ "$FREE_MB" -lt "$LOWER_MB_LIMIT" ] && { echo "🛑 可用 < ${LOWER_MB_LIMIT}MB，停止填充"; break; }
  dd if=/dev/zero of="$FILL_FILE" bs=1M count=$FILL_STEP_MB oflag=append conv=notrunc 2>/dev/null
  sync
  printf "  ‣ 已填充 %sMB，剩餘約 %sMB\n" "$FILL_STEP_MB" "$FREE_MB"
done

echo "\n🚦 執行 system_health_check.sh…";/usr/bin/system_health_check.sh

echo "\n🗂 /root/backup (最後 10 檔)："; ls -l /root/backup | tail
rm -f "$FILL_FILE" /overlay/fill.bin 2>/dev/null || true; sync
echo "✅ 填充檔已刪除，磁碟已同步。"

###############################################################################
# 3. 還原系統時間 & 重新啟用 NTP
###############################################################################
# 若 ORIGINAL_DATE 為空則略過還原
if [ -z "$ORIGINAL_DATE" ]; then
  echo "⚠️  ORIGINAL_DATE 未設定，無法還原系統時間。" >&2
else
  printf "\n🔄 還原系統時間：%s\n" "$ORIGINAL_DATE"
  if date -s "$ORIGINAL_DATE" >/dev/null 2>&1; then
    echo "✅ 系統時間已還原。"
  else
    echo "❌ 無法設定系統時間。" >&2
  fi
fi

# 手動進行一次 NTP 同步（使用 Google 時間伺服器）
echo "🌐 NTP 同步：time.google.com"
if ntpd -q -p time.google.com >/dev/null 2>&1; then
  echo "✅ 時間同步完成。"
  date
else
  echo "❌ 時間同步失敗，請檢查網路/NTP。" >&2
fi

# 重新啟動背景 NTP 服務（若存在）
if /etc/init.d/$NTP_SERVICE status >/dev/null 2>&1; then
  echo "▶️  重新啟用 $NTP_SERVICE …";
  /etc/init.d/$NTP_SERVICE restart >/dev/null || echo "⚠️  無法重新啟動 $NTP_SERVICE" >&2
else
  echo "ℹ️  未啟用 NTP 服務，略過重啟。"
fi

###############################################################################
# 4. 完成提示（直接列出結果）
###############################################################################
echo "\n📦 /root/backup 目前檔案 (時間排序)："
ls -lhtr /root/backup | tail

echo "\n📜 /overlay/log/messages 最後 20 行："
tail -n 20 /overlay/log/messages

echo "\n✅ 綜合測試完成。請確認上述輸出是否符合預期。"
