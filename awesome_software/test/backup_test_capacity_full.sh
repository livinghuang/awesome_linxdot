#!/bin/sh
###############################################################################
# Linxdot 綜合自動測試腳本 (cron 觸發 + 低空間清理) - safe/stable版
###############################################################################
set -e

# --- 可調整參數 -------------------------------------------------------------
NTP_SERVICE="sysntpd"
START_DAY="2000-01-01"
END_DAY="2000-01-09"
TIMES="01:30:00 02:00:00 03:00:00 03:10:00 03:20:00"
SLEEP_SEC=61

FILL_THRESHOLD_PCT=10          # 當前使用率未達 (100-此值)% 才會填充
FILL_STEP_MB=500               # 每次追加 500MB
LOWER_LIMIT_MB=1500            # 剩餘空間 < 1500MB 就停
MAX_TOTAL_FILL_MB=6000         # 安全保險絲：最多填到 6GB 就停

# 指向 overlay 上層（更明確）
OVERLAY_DIR="/overlay"
FILL_FILE="$OVERLAY_DIR/fill.bin"

# --- 共用工具函式 -----------------------------------------------------------
now_ts() { date +%s; }

df_read() {
  # 統一用 KB 讀取，避免不同 df 版本單位差異
  # 回傳：USED_PCT  FREE_MB
  # shellcheck disable=SC2039
  local used_kb free_kb blocks line
  line=$(df -kP "$OVERLAY_DIR" | awk 'NR==2{print}')
  # 最後三欄依序：Used(KB) Available(KB) Use%
  used_pct=$(printf "%s\n" "$line" | awk '{gsub("%","",$5); print $5}')
  free_kb=$(printf "%s\n" "$line" | awk '{print $4}')
  free_mb=$(( free_kb / 1024 ))
  printf "%s %s\n" "$used_pct" "$free_mb"
}

append_zeros_mb() {
  # 在 BusyBox 上用 stdout 重導到檔案來達成 append（通用）
  # 引數：大小(MB)
  # shellcheck disable=SC2039
  local mb=$1
  # dd 寫到 stdout，再 >> 追加到檔案
  dd if=/dev/zero bs=1M count="$mb" 2>/dev/null >> "$FILL_FILE"
  sync
}

require_date_d() {
  # 確認是否支援 -d 與 @EPOCH
  date -d "2000-01-01" +%s >/dev/null 2>&1 || {
    echo "[ERR] 此系統的 date 不支援 -d。請安裝 coreutils-date 或改用其他日期遞增方式。" >&2
    exit 1
  }
  date -d "@0" +%Y >/dev/null 2>&1 || {
    echo "[ERR] 此系統的 date 不支援 -d @EPOCH。請安裝 coreutils-date。" >&2
    exit 1
  }
}

# 安全清理：無論何種離開皆刪掉填充檔
cleanup() {
  rm -f "$FILL_FILE" 2>/dev/null || true
  sync
}
trap cleanup EXIT INT TERM

###############################################################################
# 0. 停用 NTP & 備份原始系統時間
###############################################################################
ORIGINAL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
printf "原始系統時間：%s\n" "$ORIGINAL_DATE"

if [ -x "/etc/init.d/$NTP_SERVICE" ]; then
  echo "停用 $NTP_SERVICE ..."
  /etc/init.d/$NTP_SERVICE stop >/dev/null 2>&1 || true
else
  echo "找不到 /etc/init.d/$NTP_SERVICE，略過停用。"
fi

###############################################################################
# 1. 逐日逐時模擬 → 驗證 cron 觸發 + 模擬填充磁碟空間
###############################################################################
require_date_d

start_ts=$(date -d "$START_DAY" +%s)
end_ts=$(date -d "$END_DAY" +%s)

total_filled_mb=0

while [ "$start_ts" -le "$end_ts" ]; do
  day=$(date -d "@$start_ts" +%Y-%m-%d)
  printf "\n[測試日期] %s\n" "$day"

  for t in $TIMES; do
    sim_time="$day $t"
    printf "→ 模擬系統時間：%s\n" "$sim_time"
    date -s "$sim_time" >/dev/null

    start_wait=$(now_ts)

    # 讀取使用率與剩餘（MB）
    set -- $(df_read)
    USED_PCT="$1"
    FREE_MB="$2"

    if [ "$USED_PCT" -lt $((100 - FILL_THRESHOLD_PCT)) ] && [ "$FREE_MB" -gt "$LOWER_LIMIT_MB" ]; then
      # 檢查 MAX_TOTAL_FILL_MB 保險絲
      next_fill=$FILL_STEP_MB
      if [ $((total_filled_mb + next_fill)) -gt "$MAX_TOTAL_FILL_MB" ]; then
        next_fill=$(( MAX_TOTAL_FILL_MB - total_filled_mb ))
      fi

      if [ "$next_fill" -gt 0 ]; then
        append_zeros_mb "$next_fill"
        total_filled_mb=$(( total_filled_mb + next_fill ))
        # 重新讀 df（顯示最新）
        set -- $(df_read)
        USED_PCT="$1"; FREE_MB="$2"
        printf "  ‣ 已追加 %s MB，當前剩餘約 %s MB（使用率 %s%%）\n" "$next_fill" "$FREE_MB" "$USED_PCT"
      else
        echo "  ‣ 已達到 MAX_TOTAL_FILL_MB 上限，暫停追加。"
      fi
    fi

    now_wait=$(now_ts)
    elapsed=$((now_wait - start_wait))
    remain=$((SLEEP_SEC - elapsed))
    [ $remain -lt 0 ] && remain=0
    printf "  等待 %s 秒以模擬 cron 觸發...\n" "$remain"
    [ "$remain" -gt 0 ] && sleep "$remain"

    echo "  /root 內容（時間排序）："
    ls -lhtr /root || echo "  無法讀取 /root"

    echo "  /root/backup 內容（時間排序）："
    if [ -d /root/backup ]; then
      ls -lhtr /root/backup | tail
    else
      echo "  /root/backup 不存在"
    fi

    echo "  cron / 系統日誌檢查："
    if [ -f /overlay/log/messages ]; then
      tail -n 10 /overlay/log/messages | grep -Ei 'backup|system_health|cron' || echo "  未見備份/健康檢查相關記錄"
    else
      # 備援用 logread
      logread 2>/dev/null | tail -n 50 | grep -Ei 'backup|system_health|cron' || echo "  無 /overlay/log/messages，logread 也未見關鍵字"
    fi
  done

  start_ts=$((start_ts + 86400))
done

###############################################################################
# 2. 低空間測試：直到剩餘 < LOWER_LIMIT_MB 或 使用率 >= (100-FILL_THRESHOLD_PCT)
###############################################################################
printf "\n[低空間測試] 追加至剩餘 < %d MB 或使用率達到 >= %d%% ...\n" "$LOWER_LIMIT_MB" "$((100 - FILL_THRESHOLD_PCT))"
while : ; do
  set -- $(df_read)
  USED_PCT="$1"; FREE_MB="$2"

  [ "$USED_PCT" -ge $((100 - FILL_THRESHOLD_PCT)) ] && { printf "  ✅ 使用率達 %s%%\n" "$USED_PCT"; break; }
  [ "$FREE_MB" -lt "$LOWER_LIMIT_MB" ] && { printf "  🛑 可用 < %d MB（目前 %d MB）\n" "$LOWER_LIMIT_MB" "$FREE_MB"; break; }
  [ "$total_filled_mb" -ge "$MAX_TOTAL_FILL_MB" ] && { echo "  🛑 已達 MAX_TOTAL_FILL_MB 上限"; break; }

  append_zeros_mb "$FILL_STEP_MB"
  total_filled_mb=$(( total_filled_mb + FILL_STEP_MB ))
  set -- $(df_read); USED_PCT="$1"; FREE_MB="$2"
  printf "  ‣ 已追加 %s MB，當前剩餘約 %s MB（使用率 %s%%）\n" "$FILL_STEP_MB" "$FREE_MB" "$USED_PCT"
done

echo "\n執行 system_health_check.sh ..."
set +e
/usr/bin/system_health_check.sh
SHC_EXIT=$?
set -e
[ "$SHC_EXIT" -ne 0 ] && echo "system_health_check.sh 失敗，exit=$SHC_EXIT" >&2 || echo "system_health_check.sh 成功"

echo "\n/root/backup（最後 10 檔）："
[ -d /root/backup ] && ls -l /root/backup | tail || echo "/root/backup 不存在"

###############################################################################
# 3. 還原系統時間 & 重新啟用 NTP
###############################################################################
if [ -n "$ORIGINAL_DATE" ]; then
  printf "\n還原系統時間：%s\n" "$ORIGINAL_DATE"
  if date -s "$ORIGINAL_DATE" >/dev/null 2>&1; then
    echo "系統時間已還原。"
  else
    echo "無法設定系統時間。" >&2
  fi
else
  echo "ORIGINAL_DATE 未設定，無法還原系統時間。" >&2
fi

echo "NTP 同步：time.google.com"
# BusyBox ntpd 單次同步（有些版本需要 -n -q）
if command -v ntpd >/dev/null 2>&1; then
  ntpd -q -p time.google.com >/dev/null 2>&1 || ntpd -n -q -p time.google.com >/dev/null 2>&1 || echo "時間同步失敗，請檢查網路/NTP。"
  date
fi

if [ -x "/etc/init.d/$NTP_SERVICE" ]; then
  echo "重新啟用 $NTP_SERVICE ..."
  /etc/init.d/$NTP_SERVICE restart >/dev/null 2>&1 || echo "無法重新啟動 $NTP_SERVICE" >&2
else
  echo "未啟用 NTP 服務，略過重啟。"
fi

###############################################################################
# 4. 收尾輸出
###############################################################################
echo "\n/root/backup 目前檔案（時間排序）："
[ -d /root/backup ] && ls -lhtr /root/backup | tail || echo "/root/backup 不存在"

echo "\n/overlay/log/messages 最後 20 行："
[ -f /overlay/log/messages ] && tail -n 20 /overlay/log/messages || logread 2>/dev/null | tail -n 20 || echo "找不到可用日誌來源"

echo "\n綜合測試完成。"
