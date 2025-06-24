#!/bin/sh
###############################################################################
# Linxdot 綜合自動測試腳本 (cron 觸發 + 低空間清理)
# ---------------------------------------------------------------------------
# 目的：
#   • 一鍵驗證所有安裝腳本的 crontab 排程是否在正確時間被觸發。
#   • 模擬 /overlay 空間不足情境，確定 system_health_check.sh 會自動清理
#     舊備份檔 (backup_*.tar.gz)。
#   • 測試結束後，還原原始系統時間，並重新啟用 NTP 服務。
#
# 主要流程：
#   0. 先停用 NTP（避免測試過程被自動校時）並備份原始時間。
#   1. 以「天迴圈 + 時間迴圈」方式：
#       - 從 2000‑01‑01 ~ 2000‑01‑09
#       - 每天模擬 01:30 / 02:00 / 03:00 / 03:10 / 03:20 五個時間點
#       - 每次 sleep 61 秒，讓 crond 有 1 分多鐘時間觸發排程
#   2. 以 dd 填充 /overlay，直到剩餘空間 < 5 %，立即呼叫
#      /usr/bin/system_health_check.sh 觀察是否清除舊備份。
#   3. 清理測試填充檔、sync，然後還原原始時間並啟動 NTP。
#   4. 顯示最後 10 行 /root/backup，方便檢查刪檔結果。
#
# 使用須知：
#   • 建議在測試機器或 Snapshot/VM 執行，避免影響正式服務時間。
#   • BusyBox "date -d" 在新版可用，若舊版不支援可改用純 POSIX 迴圈。
###############################################################################
set -e

# --- 可調整參數 -------------------------------------------------------------
NTP_SERVICE="sysntpd"
START_DAY="2000-01-01"
END_DAY="2000-01-09"
TIMES="01:30:00 02:00:00 03:00:00 03:10:00 03:20:00"
SLEEP_SEC=61
FILL_THRESHOLD=5
FILL_STEP_MB=50
OVERLAY_DIR="/overlay"
FILL_FILE="$OVERLAY_DIR/fill.bin"

###############################################################################
# 0. 停用 NTP & 備份原始時間
###############################################################################
ORIGINAL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "📌 原始系統時間：$ORIGINAL_DATE"

if /etc/init.d/$NTP_SERVICE status >/dev/null 2>&1; then
  echo "⏸️  停用 $NTP_SERVICE ...";
  /etc/init.d/$NTP_SERVICE stop || true
else
  echo "⚠️  找不到 $NTP_SERVICE 服務，略過停用。"
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
    echo "    等待 crond 觸發... ($SLEEP_SEC 秒)"
    for i in $(seq 1 $SLEEP_SEC); do
      printf "."
      sleep 1
    done
    echo " ✅"
  done
  start_ts=$((start_ts + 86400))
done

###############################################################################
# 2. 模擬磁碟空間不足 (<5%)，驗證自動清理
###############################################################################
echo "\n🚨 低空間測試：填充 $OVERLAY_DIR 直到剩餘 < ${FILL_THRESHOLD}%"
while : ; do
  FREE=$(df "$OVERLAY_DIR" | awk 'NR==2{gsub("%","",$(NF-1)); print $(NF-1)}')
  [ "$FREE" -le "$FILL_THRESHOLD" ] && break
  dd if=/dev/zero of="$FILL_FILE" bs=1M count=$FILL_STEP_MB oflag=append conv=notrunc 2>/dev/null
  printf "  ‣ 剩餘: %s%%\n" "$FREE"
done

/usr/bin/system_health_check.sh

echo "\n🗂 /root/backup 內容 (最後 10 檔)："
ls -l /root/backup | tail

rm -f "$FILL_FILE"
sync

###############################################################################
# 3. 還原系統時間 & 重新啟用 NTP
###############################################################################
printf "\n🔄 還原系統時間：%s\n" "$ORIGINAL_DATE"
date -s "$ORIGINAL_DATE" >/dev/null

if /etc/init.d/$NTP_SERVICE status >/dev/null 2>&1; then
  echo "▶️  重新啟用 $NTP_SERVICE ...";
  /etc/init.d/$NTP_SERVICE start || true
fi

###############################################################################
# 4. 結束 & 提醒
###############################################################################
echo "\n✅ 綜合測試完成！請檢查 /overlay/log/messages 與 /root/backup 以確認腳本在："
echo "    • 每日 01:30 / 02:00 / 03:00 / 03:10 / 03:20 皆有觸發"
echo "    • 空間不足時健康檢查腳本有自動刪除最舊備份"
