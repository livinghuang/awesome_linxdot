#!/bin/sh

# === 參數設定 ===
REMOTE_USER="ubuntu"
REMOTE_HOST="13.55.159.24"
REMOTE_PORT=22
REVERSE_PORT=2222      # EC2 對外的 port，用來反向登入 Linxdot
LOCAL_PORT=22          # Linxdot 本機 ssh port

KEY_PATH="/root/.ssh/reverse_ssh_id"
LOG_FILE="/var/log/reverse_ssh.log"

# === 開始執行 Reverse SSH ===
echo "[$(date)] Starting reverse SSH to $REMOTE_HOST:$REMOTE_PORT" >> $LOG_FILE

ssh -i "$KEY_PATH" \
    -o "ServerAliveInterval=60" \
    -o "ServerAliveCountMax=3" \
    -N -R "$REVERSE_PORT:localhost:$LOCAL_PORT" \
    "$REMOTE_USER@$REMOTE_HOST" >> $LOG_FILE 2>&1
