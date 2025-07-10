#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 安裝腳本（Mesh Gateway Border Beacon）
# 功能：將 chirpstack_gateway_mesh_border_beacon 安裝為 OpenWrt 背景服務
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

set -e  # 執行錯誤即停止
set -u  # 使用未定義變數即報錯

echo "【Linxdot Mesh Border Beacon 安裝開始】"

# ───────────────────────────────────────────────
# 基本路徑設定
# ───────────────────────────────────────────────
SERVICE_NAME="linxdot_chirpstack_gateway_mesh_border"
INITD_PATH="/etc/init.d/$SERVICE_NAME"
BINARY_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/chirpstack_gateway_mesh_border_beacon"
CONFIG_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/config/chirpstack_gateway_mesh_as_border.toml"

# ───────────────────────────────────────────────
# 舊服務移除（若已存在）
# ───────────────────────────────────────────────
if [ -f "$INITD_PATH" ]; then
    echo "[INFO] 偵測到舊服務，移除中..."
    "$INITD_PATH" stop || true
    "$INITD_PATH" disable || true
    rm -f "$INITD_PATH"
fi

# ───────────────────────────────────────────────
# 檢查檔案存在
# ───────────────────────────────────────────────
if [ ! -x "$BINARY_PATH" ]; then
    echo "[❌] 找不到可執行檔：$BINARY_PATH"
    exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
    echo "[❌] 找不到設定檔：$CONFIG_PATH"
    exit 1
fi

# ───────────────────────────────────────────────
# 建立 init.d 腳本
# ───────────────────────────────────────────────
echo "【→】建立 init.d 腳本：$INITD_PATH"
cat << EOF > "$INITD_PATH"
#!/bin/sh /etc/rc.common

# Linxdot Mesh Gateway Border Beacon Init Script
START=99
USE_PROCD=1

start_service() {
    logger -t "$SERVICE_NAME" "啟動 Border Beacon..."
    procd_open_instance
    procd_set_param command "$BINARY_PATH" -c "$CONFIG_PATH"
    procd_set_param respawn 3600 5 0
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    logger -t "$SERVICE_NAME" "停止 Border Beacon..."
}
EOF

# ───────────────────────────────────────────────
# 安裝服務、設定權限與啟動
# ───────────────────────────────────────────────
chmod +x "$INITD_PATH"
"$INITD_PATH" enable
"$INITD_PATH" start

echo "✅ Border Beacon 安裝並啟動完成"
