#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 安裝 Mesh Gateway Border (含 Beacon)
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

set -e  # 當有錯誤發生時中止執行
set -u  # 使用未定義變數會導致錯誤

SERVICE_NAME="linxdot_chirpstack_gateway_mesh_border"
INITD_PATH="/etc/init.d/$SERVICE_NAME"
SCRIPT_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/chirpstack_gateway_mesh_border_beacon"
CONFIG_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/config/chirpstack_gateway_mesh_as_border.toml"

echo "[INFO] 安裝 ChirpStack Mesh Gateway (Border Beacon)..."

# ───────────────────────────────────────────────
# 建立 init.d 服務腳本
# ───────────────────────────────────────────────

cat << EOF > "$INITD_PATH"
#!/bin/sh /etc/rc.common

# Linxdot Mesh Gateway Border Beacon Init Script
START=99
USE_PROCD=1

start_service() {
    logger -t "$SERVICE_NAME" "啟動 Border Beacon..."
    procd_open_instance
    procd_set_param command "$SCRIPT_PATH" -c "$CONFIG_PATH"
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
# 設定權限與啟動
# ───────────────────────────────────────────────

chmod +x "$INITD_PATH"
"$INITD_PATH" enable
"$INITD_PATH" start

echo "[OK] Border Beacon 安裝並啟動完成"
