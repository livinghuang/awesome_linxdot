#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 安裝腳本（Mesh Relay 服務）
# 功能：安裝 ChirpStack Mesh Gateway（Relay）至 OpenWrt 系統服務
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

set -e  # 當有錯誤發生時中止執行
set -u  # 使用未定義變數會導致錯誤
echo "【Linxdot Mesh Relay 安裝開始】"

SERVICE_NAME="linxdot_chirpstack_gateway_mesh_relay"
INITD_PATH="/etc/init.d/$SERVICE_NAME"

# 如果已經存在同名 init.d，就先停用舊服務
if [ -f "$INITD_PATH" ]; then
    echo "[INFO] 偵測到已有 $SERVICE_NAME，重新安裝..."
    $INITD_PATH stop || true
    $INITD_PATH disable || true
    rm -f "$INITD_PATH"
fi

# 主要程式與設定檔路徑
SCRIPT_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh_relay"
BINARY_PATH="$SCRIPT_PATH/chirpstack_gateway_mesh_binary/chirpstack_gateway_mesh_relay"
INITD_TEMPLATE="$SCRIPT_PATH/chirpstack_gateway_mesh_relay.initd"
CONFIG_PATH="$SCRIPT_PATH/chirpstack_gateway_mesh_binary/config/chirpstack_gateway_mesh_as_relay.toml"


# 【1】檢查檔案是否存在
if [ ! -x "$BINARY_PATH" ]; then
    echo "[❌] 找不到可執行檔：$BINARY_PATH"
    exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
    echo "[❌] 找不到設定檔：$CONFIG_PATH"
    exit 1
fi

if [ ! -f "$INITD_TEMPLATE" ]; then
    echo "[❌] 找不到 init.d 腳本：$INITD_TEMPLATE"
    exit 1
fi

echo "【✔】Binary、Config、Init Script 檢查通過"

# 【2】複製 init.d 腳本到系統
echo "【→】複製 init.d 腳本到 $INITD_PATH"
cp "$INITD_TEMPLATE" "$INITD_PATH"
chmod +x "$INITD_PATH"

# 【3】啟用與啟動服務
echo "【→】啟用並啟動 Mesh Relay 系統服務"
$INITD_PATH enable
$INITD_PATH start

echo "✅ ChirpStack Mesh Gateway（Relay 模式）安裝完成。"
