#!/bin/sh

CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"

# === 檢查設定檔 ===
if [ ! -f "$CONF_PATH" ]; then
  echo "[❌] 找不到註冊資訊，請先執行 register.sh"
  exit 1
fi

REMOTE_HOST=$(jq -r .remote_host "$CONF_PATH")
REVERSE_PORT=$(jq -r .assigned_reverse_port "$CONF_PATH")
REMOTE_USER=$(jq -r .user "$CONF_PATH")

# === 建立 Reverse SSH 隧道 ===
ssh -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -N -R "${REVERSE_PORT}:localhost:22" \
    "${REMOTE_USER}@${REMOTE_HOST}" >> "$LOG_FILE" 2>&1

