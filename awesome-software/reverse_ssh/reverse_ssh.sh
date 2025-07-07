#!/bin/sh

# === [基本設定] ===
BASE_DIR="/opt/awesome_linxdot/awesome-software/reverse_ssh"
CONF_PATH="$BASE_DIR/reverse_ssh.conf"
KEY_PATH="$BASE_DIR/reverse_ssh_id"
LOG_FILE="/var/log/reverse_ssh.log"
LOCK_FILE="/tmp/reverse_ssh.lock"
TMP_PAYLOAD="/tmp/register_payload.json"
API_URL="http://52.43.133.220:8081/register"
LOOP_SCRIPT="$BASE_DIR/reverse_ssh_loop.sh"

DEVICE_MAC=$(cat /sys/class/net/eth0/address 2>/dev/null | tr -d ':')
[ -n "$DEVICE_MAC" ] && DEVICE_NAME="Linxdot-$DEVICE_MAC" || DEVICE_NAME="Linxdot-$(cat /proc/sys/kernel/hostname)"

touch "$LOG_FILE"

# === 金鑰輪替 ===
NOW_HOUR=$(date +%H)
NOW_MIN=$(date +%M)
[ "$NOW_HOUR" = "00" ] && [ "$NOW_MIN" -lt 10 ] && {
  echo "[$(date)] 🔁 金鑰輪替" >> "$LOG_FILE"
  rm -f "$KEY_PATH" "$KEY_PATH.pub"
}

# === 金鑰產生 ===
if [ ! -f "$KEY_PATH" ]; then
  echo "[$(date)] 🔐 產生 SSH 金鑰" >> "$LOG_FILE"
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""
else
  echo "[$(date)] ✅ 金鑰已存在" >> "$LOG_FILE"
fi

# === Dropbear 啟動確認 ===
if ! echo | nc localhost 22 >/dev/null 2>&1; then
  echo "[$(date)] ⚠️ port 22 未開，啟動 dropbear" >> "$LOG_FILE"
  /etc/init.d/dropbear start
  sleep 2
fi

# === 註冊請求 ===
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
echo "[$(date)] ✅ 註冊成功，資訊儲存" >> "$LOG_FILE"

# === 防止重複連線 ===
if [ -f "$LOCK_FILE" ]; then
  OLD_PID=$(cat "$LOCK_FILE")
  [ -d "/proc/$OLD_PID" ] && {
    echo "[$(date)] ⚠️ 已在執行中 (PID $OLD_PID)" >> "$LOG_FILE"
    exit 0
  }
fi
echo $$ > "$LOCK_FILE"

# === 讀取設定 ===
REMOTE_HOST=$(jq -r .remote_host "$CONF_PATH")
REVERSE_PORT=$(jq -r .assigned_reverse_port "$CONF_PATH")
REMOTE_USER=$(jq -r .user "$CONF_PATH")

if [ -z "$REMOTE_HOST" ] || [ -z "$REVERSE_PORT" ] || [ -z "$REMOTE_USER" ]; then
  echo "[$(date)] ❌ 無效設定" >> "$LOG_FILE"
  rm -f "$LOCK_FILE"
  exit 1
fi

echo "[$(date)] 🚀 啟動 Reverse SSH 至 $REMOTE_USER@$REMOTE_HOST:$REVERSE_PORT" >> "$LOG_FILE"

# === 寫入實際連線用的 loop 腳本 ===
cat <<EOF > "$LOOP_SCRIPT"
#!/bin/sh
while true; do
  echo "[\$(date)] ⚙️ 建立 SSH 連線..." >> "$LOG_FILE"

  ssh -i "$KEY_PATH" \\
      -o StrictHostKeyChecking=no \\
      -o UserKnownHostsFile=/dev/null \\
      -o ServerAliveInterval=60 \\
      -o ServerAliveCountMax=3 \\
      -o ConnectTimeout=10 \\
      -N -R "$REVERSE_PORT:localhost:22" \\
      "$REMOTE_USER@$REMOTE_HOST" >> "$LOG_FILE" 2>&1

  echo "[\$(date)] 🔁 SSH 連線中斷，10 秒後重試" >> "$LOG_FILE"
  sleep 10
done
EOF

chmod +x "$LOOP_SCRIPT"

# === 背景啟動 loop 腳本 ===
"$LOOP_SCRIPT" &
echo "[$(date)] ✅ Reverse SSH 背景已啟動 (PID \$!)" >> "$LOG_FILE"
