#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot MQTT Forwarder (Border) Installer
# 安裝 chirpstack_mqtt_forwarder 作為 Mesh Border 用 MQTT forwarder 服務
# 適用機種：Linxdot + SX1302 + OpenWrt
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

echo "【Linxdot MQTT Forwarder (as Border) 安裝開始】"

# ───────────────────────────────────────────────
# 基本路徑與檔案名稱
# ───────────────────────────────────────────────
base_dir="/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder"
binary_dir="$base_dir/chirpstack_mqtt_forwarder_binary"
bin_file="$binary_dir/chirpstack_mqtt_forwarder"
config_file="$binary_dir/chirpstack_mqtt_forwarder_as_gateway_mesh_border.toml"
initd_template="$binary_dir/chirpstack_mqtt_forwarder_as_border.initd"
initd_target="/etc/init.d/linxdot_chirpstack_mqtt_forwarder_as_border"

# ───────────────────────────────────────────────
# 【步驟 1】檢查檔案是否存在
# ───────────────────────────────────────────────
if [ ! -x "$bin_file" ]; then
    echo "[❌] 執行檔不存在：$bin_file"
    exit 1
fi

if [ ! -f "$config_file" ]; then
    echo "[❌] 設定檔不存在：$config_file"
    exit 1
fi

if [ ! -f "$initd_template" ]; then
    echo "[❌] Init.d 腳本不存在：$initd_template"
    exit 1
fi

echo "【✔】Binary、Config、Init Script 檢查通過"

# ───────────────────────────────────────────────
# 【步驟 2】複製 init.d 腳本至 /etc/init.d
# ───────────────────────────────────────────────
echo "【→】複製 init.d 腳本到 $initd_target"
cp "$initd_template" "$initd_target"
chmod +x "$initd_target"

# ───────────────────────────────────────────────
# 【步驟 3】啟用並啟動服務
# ───────────────────────────────────────────────
echo "【→】啟用並啟動 MQTT forwarder (as border) 系統服務"
$initd_target enable
$initd_target start

echo "✅ ChirpStack MQTT Forwarder (as Border) 安裝完成。"
