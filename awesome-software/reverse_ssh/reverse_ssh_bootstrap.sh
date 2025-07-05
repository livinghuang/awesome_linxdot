#!/bin/sh

CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"
LOG_FILE="/var/log/reverse_ssh.log"
LOCK_FILE="/tmp/reverse_ssh.lock"
TMP_PAYLOAD="/tmp/register_payload.json"
API_URL="http://13.55.159.24:8080/register"
DEVICE_NAME="$(cat /proc/sys/kernel/hostname)"

# === 建立 log 檔（如無）===
touch "$LOG_FILE"

# === 金鑰輪替：刪除舊的 SSH 金鑰 ===
if [ -f "$KEY_PATH" ]; then
  echo "[$(date)] 🔁 輪替：刪除舊金鑰" >> "$LOG_FILE"
  rm -f "$KEY_PATH" "$KEY_PATH.pub"
fi

# === 重新產生 SSH 金鑰 ===
ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
echo "[$(date)] 🔐 新 SSH 金鑰產生完成" >> "$LOG_FILE"

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
  echo "[$(date)] ❌ 註冊失敗：$RESPONSE" >> "$LOG_FILE"
  exit 1
fi

echo "$RESPONSE" > "$CONF_PATH"
echo "[$(date)] ✅ 註冊成功，資訊寫入 $CONF_PATH" >> "$LOG_FILE"

# === 檢查是否已經有連線執行中 ===
if [ -f "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  if [ -d "/proc/$OLD_PID" ]; then
    echo "[$(date)] ⚠️ SSH 已在執行 (PID $OLD_PID)，跳過連線啟動" >> "$LOG_FILE"
    exit 0
  fi
fi
echo $$ > "$LOCK_FILE"

# === 讀取 conf 並啟動 Reverse SSH ===
REMOTE_HOST=$(jq -r .remote_host "$CONF_PATH")
REVERSE_PORT=$(jq -r .assigned_reverse_port "$CONF_PATH")
REMOTE_USER=$(jq -r .user "$CONF_PATH")

if [ -z "$REMOTE_HOST" ] || [ -z "$REVERSE_PORT" ] || [ -z "$REMOTE_USER" ]; then
  echo "[$(date)] ❌ 設定讀取錯誤，請檢查 $CONF_PATH" >> "$LOG_FILE"
  rm -f "$LOCK_FILE"
  exit 1
fi

echo "[$(date)] 🚀 建立 Reverse SSH 至 $REMOTE_USER@$REMOTE_HOST:$REVERSE_PORT" >> "$LOG_FILE"

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

rm -f "$LOCK_FILE"
