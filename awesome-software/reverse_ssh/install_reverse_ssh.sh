#!/bin/sh

# === 安裝目錄設定 ===
INSTALL_DIR="/opt/awesome_linxdot/awesome-software/reverse_ssh"
INITD_TARGET="/etc/init.d/reverse_ssh"
SCRIPT_TARGET="$INSTALL_DIR/reverse_ssh.sh"

# === 建立目錄 ===
echo "[*] 建立目錄 $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# === 複製主腳本 ===
echo "[*] 複製 reverse_ssh.sh 至 $SCRIPT_TARGET"
cp reverse_ssh.sh "$SCRIPT_TARGET"
chmod +x "$SCRIPT_TARGET"

# === 複製 init.d 腳本 ===
echo "[*] 複製 init.d 腳本至 $INITD_TARGET"
cp reverse_ssh.initd "$INITD_TARGET"
chmod +x "$INITD_TARGET"

# === 設為開機自啟 ===
echo "[*] 啟用開機自動啟動"
$INITD_TARGET enable

# === 立即啟動服務 ===
echo "[*] 啟動 reverse_ssh 服務"
$INITD_TARGET start

echo "[✔] Reverse SSH 安裝完成並啟動成功"
