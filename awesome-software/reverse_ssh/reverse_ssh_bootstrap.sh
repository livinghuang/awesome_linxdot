#!/bin/sh

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

# === 啟動 dropbear（如未啟動）===
if ! echo | nc localhost 22 >/dev/null 2>&1; then
  echo "[$(date)] ⚠️ 本地 SSH port 22 未開啟，嘗試啟動 dropbear" >> "$LOG_FILE"
  /etc/init.d/dropbear start
  sleep 2
fi

# === 若金鑰不存在則產生 ===
if [ ! -f "$KEY_PATH" ]; then
  echo "[$(date)] 🔐 產生新 SSH 金鑰" >> "$LOG_FILE"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
else
  echo "[$(date)] ✅ SSH 金鑰已存在，跳過產生" >> "$LOG_FILE"
fi

# === 發送註冊請求 ===
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

# === 清除舊連線（如有）===
if [ -f "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  if [ -d "/proc/$OLD_PID" ]; then
    echo "[$(date)] ⚠️ 舊連線進程存在 (PID $OLD_PID)，先行終止" >> "$LOG_FILE"
    kill "$OLD_PID"
    sleep 2
  fi
  rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"

# === 讀取連線參數 ===
REMOTE_HOST=$(grep -o '"remote_host": *"[^"]*"' "$CONF_PATH" | cut -d'"' -f4)
REVERSE_PORT=$(grep -o '"assigned_reverse_port": *[0-9]*' "$CONF_PATH" | grep -o '[0-9]*')
REMOTE_USER=$(grep -o '"user": *"[^"]*"' "$CONF_PATH" | cut -d'"' -f4)

if [ -z "$REMOTE_HOST" ] || [ -z "$REVERSE_PORT" ] || [ -z "$REMOTE_USER" ]; then
  echo "[$(date)] ❌ 設定讀取錯誤，請檢查 $CONF_PATH" >> "$LOG_FILE"
  rm -f "$LOCK_FILE"
  exit 1
fi

echo "[$(date)] 🚀 建立 Reverse SSH 至 $REMOTE_USER@$REMOTE_HOST:$REVERSE_PORT" >> "$LOG_FILE"

# === 建立永續連線 ===
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
