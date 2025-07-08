#!/bin/sh

# === 安裝目錄設定 ===
INSTALL_DIR="/opt/awesome_linxdot/awesome_software/reverse_ssh"
INITD_TARGET="/etc/init.d/reverse_ssh"
SCRIPT_TARGET="$INSTALL_DIR/reverse_ssh.sh"

# === 複製 init.d 腳本 ===
echo "[*] 複製 init.d 腳本至 $INITD_TARGET"
cp "$INSTALL_DIR/reverse_ssh.initd" "$INITD_TARGET"
chmod +x "$INITD_TARGET"

# === 設為開機自啟 ===
echo "[*] 啟用開機自動啟動"
"$INITD_TARGET" enable

# === 立即啟動服務 ===
echo "[*] 啟動 reverse_ssh 服務"
"$INITD_TARGET" start

echo "[✔] Reverse SSH 安裝完成並啟動成功"
