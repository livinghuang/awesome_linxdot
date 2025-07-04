#!/bin/sh

API_URL="http://13.55.159.24:8080/register"
CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"
DEVICE_NAME="$(cat /proc/sys/kernel/hostname)"
PUB_KEY="$KEY_PATH.pub"

# === 確保 jq 存在 ===
if ! command -v jq >/dev/null 2>&1; then
    echo "[❌] jq 未安裝，請執行：opkg install jq"
    exit 1
fi

# === 產生 SSH 金鑰（如尚未產生）===
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
fi

# === 建立 JSON payload ===
PAYLOAD=$(printf '{
  "device_name": "%s",
  "public_key": "%s",
  "firmware_version": "v1.0"
}' "$DEVICE_NAME" "$(cat $PUB_KEY)")

# === 使用 wget 傳送 POST 請求 ===
RESPONSE=$(wget -qO- --header="Content-Type: application/json" \
  --post-data="$PAYLOAD" "$API_URL")

if [ -z "$RESPONSE" ] || echo "$RESPONSE" | grep -q "error"; then
    echo "[❌] 註冊失敗，請確認 API 可連線或請求格式正確"
    exit 1
fi

# === 儲存回傳資訊 ===
if ! echo "$RESPONSE" | jq . > "$CONF_PATH"; then
    echo "[❌] 無法寫入 $CONF_PATH"
    exit 1
fi

echo "[✔] 註冊完成，資訊已寫入 $CONF_PATH"
