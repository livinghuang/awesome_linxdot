#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 安裝腳本（Mesh Relay 服務）
# 功能：安裝 ChirpStack Mesh Gateway（Relay）至 OpenWrt 系統服務
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

echo "【Linxdot Mesh Relay 安裝開始】"

SERVICE_NAME="linxdot_chirpstack_gateway_mesh_relay"
INITD_PATH="/etc/init.d/$SERVICE_NAME"

# 主要程式與設定檔路徑
BINARY_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/chirpstack_gateway_mesh_relay"
CONFIG_PATH="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/config/chirpstack_gateway_mesh_as_relay.toml"
INITD_TEMPLATE="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/chirpstack_gateway_mesh_relay.initd"

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
