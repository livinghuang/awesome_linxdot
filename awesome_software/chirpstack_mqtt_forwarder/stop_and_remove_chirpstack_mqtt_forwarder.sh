#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot MQTT Forwarder Uninstaller
# 停用並移除 MQTT Forwarder 的 init.d 背景服務
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

initd_service="/etc/init.d/linxdot_chirpstack_mqtt_forwarder"

echo "【MQTT Forwarder 移除程序開始】"

# 【1】檢查服務是否存在
if [ -f "$initd_service" ]; then
    echo "【→】關閉服務..."
    $initd_service stop
    $initd_service disable

    echo "【→】移除 init.d 腳本..."
    rm -f "$initd_service"
else
    echo "【⚠】找不到 MQTT Forwarder init.d 腳本，可能已移除。"
fi

# 【2】保留 binary/config（如需一併清除可加下列行）
# echo "【→】可選擇清除 binary 與設定檔..."
# rm -rf /opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder

echo "✅ MQTT Forwarder 服務停用與移除完成。"
