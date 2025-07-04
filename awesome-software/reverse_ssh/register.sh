#!/bin/sh

CONF_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh.conf"
KEY_PATH="/opt/awesome_linxdot/awesome-software/reverse_ssh/reverse_ssh_id"
LOG_FILE="/var/log/reverse_ssh.log"
LOCK_FILE="/tmp/reverse_ssh.lock"

# === 建立 log 檔（如無）===
touch "$LOG_FILE"

# === 檢查鎖定（避免重複執行）===
if [ -f "$LOCK_FILE" ]; then
    OLD_PID=$(cat "$LOCK_FILE")
    if [ -d "/proc/$OLD_PID" ]; then
        echo "[$(date)] 已有 SSH 正在執行 (PID $OLD_PID)，跳過啟動" >> "$LOG_FILE"
        exit 0
    fi
fi
echo $$ > "$LOCK_FILE"

# === 讀取註冊資訊 ===
REMOTE_HOST=$(jq -r .remote_host "$CONF_PATH")
REVERSE_PORT=$(jq -r .assigned_reverse_port "$CONF_PATH")
REMOTE_USER=$(jq -r .user "$CONF_PATH")

if [ -z "$REMOTE_HOST" ] || [ -z "$REVERSE_PORT" ] || [ -z "$REMOTE_USER" ]; then
    echo "[$(date)] [ERROR] 設定讀取失敗，請先執行 register.sh" >> "$LOG_FILE"
    rm -f "$LOCK_FILE"
    exit 1
fi

echo "[$(date)] 建立 Reverse SSH 至 $REMOTE_USER@$REMOTE_HOST:$REVERSE_PORT" >> "$LOG_FILE"

# === 進入自動重連 loop ===
while true; do
    ssh -i "$KEY_PATH" \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -o ConnectTimeout=10 \
        -N -R "${REVERSE_PORT}:localhost:22" \
        "${REMOTE_USER}@${REMOTE_HOST}" >> "$LOG_FILE" 2>&1

    echo "[$(date)] SSH 連線中斷，10 秒後重試" >> "$LOG_FILE"
    sleep 10
done

# === 清除鎖定（理論上不會執行到這）===
rm -f "$LOCK_FILE"
