#!/bin/sh

# === [設定變數區] ===
CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"  # 登記 API 回傳資料儲存路徑
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"     # SSH 金鑰儲存路徑
LOG_FILE="/var/log/reverse_ssh.log"                                              # Log 紀錄檔
LOCK_FILE="/tmp/reverse_ssh.lock"                                                # 避免重複執行用的 lock file
TMP_PAYLOAD="/tmp/register_payload.json"                                         # 註冊暫存 payload
API_URL="http://52.43.133.220:8081/register"                                     # 註冊 API 端點

# 嘗試取得裝置 MAC，用來生成唯一 Device Name
DEVICE_MAC=$(cat /sys/class/net/eth0/address 2>/dev/null | tr -d ':')
if [ -n "$DEVICE_MAC" ]; then
  DEVICE_NAME="Linxdot-$DEVICE_MAC"
else
  DEVICE_NAME="Linxdot-$(cat /proc/sys/kernel/hostname)"
fi

# === [Log 初始化] ===
touch "$LOG_FILE"

# === [每日凌晨 00:00~00:09 時段輪替 SSH 金鑰] ===
NOW_HOUR=$(date +%H)
NOW_MIN=$(date +%M)
if [ "$NOW_HOUR" = "00" ] && [ "$NOW_MIN" -lt 10 ]; then
  echo "[$(date)] 🔁 輪替時段內（00:00~00:10），刪除舊 SSH 金鑰" >> "$LOG_FILE"
  rm -f "$KEY_PATH" "$KEY_PATH.pub"
fi

# === [若金鑰不存在則建立] ===
if [ ! -f "$KEY_PATH" ]; then
  echo "[$(date)] 🔐 產生新 SSH 金鑰" >> "$LOG_FILE"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
else
  echo "[$(date)] ✅ SSH 金鑰已存在，跳過產生" >> "$LOG_FILE"
fi

# === [送出註冊請求到 API Server] ===
echo "[$(date)] 📡 傳送註冊請求至 $API_URL" >> "$LOG_FILE"

cat <<EOF > "$TMP_PAYLOAD"
{
  "device_name": "$DEVICE_NAME",
  "public_key": "$(cat $KEY_PATH.pub)",
  "firmware_version": "v1.0"
}
EOF

RESPONSE=$(wget -qO- --post-file="$TMP_PAYLOAD" "$API_URL")
rm -f "$TMP_PAYLOAD"

# 檢查註冊回應
if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q "error"; then
  echo "[$(date)] ❌ 註冊失敗：$RESPONSE，10 秒後重試" >> "$LOG_FILE"
  sleep 10
  exit 1
fi

# 儲存註冊回傳結果（remote_host / user / assigned_reverse_port）
echo "$RESPONSE" > "$CONF_PATH"
echo "[$(date)] ✅ 註冊成功，資訊寫入 $CONF_PATH" >> "$LOG_FILE"

# === [確認 Dropbear 是否有啟動：避免連不回來] ===
if ! echo | nc localhost 22 >/dev/null 2>&1; then
  echo "[$(date)] ⚠️ 本地 SSH port 22 未開啟，嘗試啟動 dropbear" >> "$LOG_FILE"
  /etc/init.d/dropbear start
  sleep 2
fi

# === [檢查是否已有連線進程，避免重複啟動] ===
if [ -f "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  if [ -d "/proc/$OLD_PID" ]; then
    echo "[$(date)] ⚠️ Reverse SSH 已在執行中 (PID $OLD_PID)，跳過啟動" >> "$LOG_FILE"
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"

# === [從回傳設定檔讀取 Reverse 連線參數] ===
REMOTE_HOST=$(jq -r .remote_host "$CONF_PATH")
REVERSE_PORT=$(jq -r .assigned_reverse_port "$CONF_PATH")
REMOTE_USER=$(jq -r .user "$CONF_PATH")

if [ -z "$REMOTE_HOST" ] || [ -z "$REVERSE_PORT" ] || [ -z "$REMOTE_USER" ]; then
  echo "[$(date)] ❌ 設定讀取錯誤，請檢查 $CONF_PATH" >> "$LOG_FILE"
  rm -f "$LOCK_FILE"
  exit 1
fi

echo "[$(date)] 🚀 建立 Reverse SSH 至 $REMOTE_USER@$REMOTE_HOST:$REVERSE_PORT" >> "$LOG_FILE"

# === [建立 Reverse SSH 隧道並持續背景重試] ===
(
  while true; do
    ssh -i "$KEY_PATH" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -o ConnectTimeout=10 \
        -N -R "${REVERSE_PORT}:localhost:22" \
        "${REMOTE_USER}@${REMOTE_HOST}" >> "$LOG_FILE" 2>&1

    echo "[$(date)] 🔁 SSH 連線中斷，10 秒後重試" >> "$LOG_FILE"
    sleep 10
  done
) &

echo "[$(date)] ✅ Reverse SSH 隧道已背景啟動完成" >> "$LOG_FILE"
