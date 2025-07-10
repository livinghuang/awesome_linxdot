#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot MQTT Forwarder Installer
# 安裝 chirpstack_mqtt_forwarder 為 OpenWrt 背景服務
# 適用機種：Linxdot + SX1302 + OpenWrt
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

echo "【Linxdot MQTT Forwarder 安裝開始】"

# 設定資料路徑
binary_dir="/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/chirpstack_mqtt_forwarder_binary"
bin_file="$binary_dir/chirpstack_mqtt_forwarder"
config_file="$binary_dir/chirpstack_mqtt_forwarder.toml"
initd_template="$binary_dir/chirpstack_mqtt_forwarder.initd"
initd_target="/etc/init.d/linxdot_chirpstack_mqtt_forwarder"

# 【1】確認 binary 與 config 是否存在
if [ ! -x "$bin_file" ]; then
    echo "[❌] 執行檔不存在：$bin_file"
    exit 1
fi

if [ ! -f "$config_file" ]; then
    echo "[❌] 設定檔不存在：$config_file"
    exit 1
fi

echo "【✔】Binary 與 Config 檢查通過"

# 【2】複製 init.d 服務腳本
echo "【→】複製 init.d 腳本到 $initd_target"
cp "$initd_template" "$initd_target"
chmod +x "$initd_target"

# 【3】設定開機啟動與立即啟動
echo "【→】啟用與啟動 MQTT forwarder 系統服務"
$initd_target enable
$initd_target start

echo "✅ ChirpStack MQTT Forwarder 安裝完成。"
