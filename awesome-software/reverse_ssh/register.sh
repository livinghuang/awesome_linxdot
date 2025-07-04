#!/bin/sh

API_URL="http://13.55.159.24:8080/register"
CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"
DEVICE_NAME="$(hostname)"
PUB_KEY="$KEY_PATH.pub"

# === 產生 SSH 金鑰（如尚未產生）===
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
fi

# === 傳送註冊請求 ===
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "device_name": "'"$DEVICE_NAME"'",
    "public_key": "'"$(cat $PUB_KEY)"'",
    "firmware_version": "v1.0"
  }')

# === 儲存回傳資訊 ===
echo "$RESPONSE" | jq . > "$CONF_PATH"

echo "[✔] 註冊完成，資訊已寫入 $CONF_PATH"
