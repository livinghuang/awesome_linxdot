#!/bin/sh

# === [設定變數區] ===
CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"
LOG_FILE="/var/log/reverse_ssh.log"
LOCK_FILE="/tmp/reverse_ssh.lock"
TMP_PAYLOAD="/tmp/register_payload.json"
API_URL="http://52.43.133.220:8081/register"

DEVICE_MAC=$(cat /sys/class/net/eth0/address 2>/dev/null | tr -d ':')
if [ -n "$DEVICE_MAC" ]; then
  DEVICE_NAME="Linxdot-$DEVICE_MAC"
else
  DEVICE_NAME="Linxdot-$(cat /proc/sys/kernel/hostname)"
fi

# === 建立 log 檔案（如無）===
touch "$LOG_FILE"

# === 輪替金鑰（00:00 ~ 00:09）===
NOW_HOUR=$(date +%H)
NOW_MIN=$(date +%M)
if [ "$NOW_HOUR" = "00" ] && [ "$NOW_MIN" -lt 10 ]; then
  echo "[$(date)] 🔁 輪替時段內，刪除舊 SSH 金鑰" >> "$LOG_FILE"
  rm -f "$KEY_PATH" "$KEY_PATH.pub"
fi

# === 建立金鑰（如無）===
if [ ! -f "$KEY_PATH" ]; then
  echo "[$(date)] 🔐 產生新 SSH 金鑰" >> "$LOG_FILE"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
else
  echo "[$(date)] ✅ SSH 金鑰已存在，跳過產生" >> "$LOG_FILE"
fi

# === 傳送註冊資訊 ===
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

if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q "error"; then
  echo "[$(date)] ❌ 註冊失敗：$RESPONSE，10 秒後重試" >> "$LOG_FILE"
  sleep 10
  exit 1
fi

echo "$RESPONSE" > "$CONF_PATH"
echo "[$(date)] ✅ 註冊成功，資訊寫入 $CONF_PATH" >> "$LOG_FILE"

# === 確保本機 port 22 可用（啟動 Dropbear）===
if ! echo | nc localhost 22 >/dev/null 2>&1; then
  echo "[$(date)] ⚠️ 本地 SSH port 22 未開啟，嘗試啟動 dropbear" >> "$LOG_FILE"
  /etc/init.d/dropbear start
  sleep 2
fi

# === 檢查是否已有連線進程 ===
if [ -f "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  if [ -d "/proc/$OLD_PID" ]; then
    echo "[$(date)] ⚠️ Reverse SSH 已在執行中 (PID $OLD_PID)，跳過啟動" >> "$LOG_FILE"
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"

# === 讀取連線參數 ===
REMOTE_HOST=$(jq -r .remote_host "$CONF_PATH")
REVERSE_PORT=$(jq -r .assigned_reverse_port "$CONF_PATH")
REMOTE_USER=$(jq -r .user "$CONF_PATH")

if [ -z "$REMOTE_HOST" ] || [ -z "$REVERSE_PORT" ] || [ -z "$REMOTE_USER" ]; then
  echo "[$(date)] ❌ 設定讀取錯誤，請檢查 $CONF_PATH" >> "$LOG_FILE"
  rm -f "$LOCK_FILE"
  exit 1
fi

# === 使用 nohup 執行背景反向 SSH 隧道連線 ===
echo "[$(date)] 🧪 啟動 SSH 背景程序（測試模式）" >> "$LOG_FILE"

nohup /bin/sh -c "
  echo \"[\$(date)] 🧪 進入 while 迴圈\" >> '$LOG_FILE'
  while true; do
    echo \"[\$(date)] ⚙️ 嘗試建立 SSH 連線...\" >> '$LOG_FILE'

    ssh -i '$KEY_PATH' \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -o ConnectTimeout=10 \
        -N -R '${REVERSE_PORT}:localhost:22' \
        '${REMOTE_USER}@${REMOTE_HOST}' >> '$LOG_FILE' 2>&1

    echo \"[\$(date)] 🔁 SSH 連線中斷，10 秒後重試\" >> '$LOG_FILE'
    sleep 10
  done
" >> "$LOG_FILE" 2>&1 &

echo "[$(date)] ✅ 背景程序已啟動（請觀察 log 是否進入 while）" >> "$LOG_FILE"

