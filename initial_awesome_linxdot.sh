#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 初始化安裝腳本
# 功能：安裝 Linxdot 所需各模組、清理舊服務、建立完整架構
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

set -e  # 有錯誤時中斷
set -u  # 使用未定義變數時中斷

echo "========== Linxdot 系統初始化開始 =========="

# ───────────────────────────────────────────────
# Step 0: 安裝 Cron 與 Reverse SSH
# ───────────────────────────────────────────────

echo "[INFO] 設定 Cron 任務同步..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] 設定 Cron 失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Reverse SSH 服務..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] 安裝 Reverse SSH 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 1: 停用舊的 Linxdot 與 Watchcat 服務（若存在）
# ───────────────────────────────────────────────

for svc in \
  linxdot-lora-pkt-fwd \
  linxdot-chripstack-service \
  linxdot_check \
  linxdot_setup \
  watchcat; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 停用舊服務：$svc..."
    /etc/init.d/$svc stop
    /etc/init.d/$svc disable
    rm -f /etc/init.d/$svc
  fi
done

# ───────────────────────────────────────────────
# Step 2: 安裝本地 ChirpStack Server
# ───────────────────────────────────────────────

echo "[INFO] 安裝本地 ChirpStack Server..."
/opt/awesome_linxdot/awesome_software/chirpstack_server/install_chirpstack_server.sh || {
  echo "[ERROR] 安裝本地 ChirpStack Server 失敗" >&2
  exit 1
}

echo "[INFO] 安裝 ChirpStack Device Activator..."
/opt/awesome_linxdot/awesome_software/chirpstack_device_activator/install_chirpstack_device_activator.sh || {
  echo "[ERROR] 安裝 ChirpStack Device Activator 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 3: 安裝 ChirpStack Concentratord
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack Concentratord..."
/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh || {
  echo "[ERROR] 安裝 ChirpStack Concentratord 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 4: 安裝 ChirpStack UDP Forwarder
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack UDP Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh || {
  echo "[ERROR] 安裝 ChirpStack UDP Forwarder 失敗" >&2
  exit 1
}

# Step 5: 安裝 ChirpStack Mesh Gateway（Border Beacon 版本）
echo "[INFO] 安裝 ChirpStack Mesh Gateway (Border Beacon)..."
/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh_border_beacon.sh || {
  echo "[ERROR] 安裝 ChirpStack Mesh Gateway Border Beacon 失敗" >&2
  exit 1
}


# ───────────────────────────────────────────────
# Step 6: 安裝 ChirpStack MQTT Forwarder
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack MQTT Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install_chirpstack_mqtt_forwarder.sh || {
  echo "[ERROR] 安裝 ChirpStack MQTT Forwarder 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# 結尾說明
# ───────────────────────────────────────────────

echo "✅ Linxdot LoRaWAN 架構初始化完成！"

# 架構備註：
#   SX1302 → concentratord → UDP forwarder → Local ChirpStack Server
#                          → Mesh Gateway → MQTT forwarder → Cloud Server
