#!/bin/sh

API_URL="http://13.55.159.24:8080/register"
CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"
DEVICE_NAME="$(cat /proc/sys/kernel/hostname)"
PUB_KEY="$KEY_PATH.pub"

# === 確保工具存在 ===
if ! command -v curl >/dev/null 2>&1; then
    opkg update && opkg install curl
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "[❌] jq 未安裝，請執行：opkg install jq"
    exit 1
fi

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

if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q "error"; then
    echo "[❌] 註冊失敗，請檢查網路與 API Server"
    exit 1
fi

# === 儲存回傳資訊 ===
if ! echo "$RESPONSE" | jq . > "$CONF_PATH"; then
    echo "[❌] 無法寫入 $CONF_PATH"
    exit 1
fi

echo "[✔] 註冊完成，資訊已寫入 $CONF_PATH"
