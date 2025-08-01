#!/bin/sh

###############################################################################
# Linxdot OpenSource - 初始化安裝腳本（Border 版）
# 功能：設定 Linxdot 為 LoRa Mesh Border Gateway，並連線至遠端 ChirpStack Cloud
# Author: Living Huang
# Version: v1.2.0
# Updated: 2025-08-01
###############################################################################

set -e
set -u

echo "========== 🟢 Linxdot Border Gateway 初始化開始 =========="

# ───────────────────────────────────────────────
# [Pre-Step] 移除 chirpstack-docker（如存在）
# ───────────────────────────────────────────────
docker_chirpstack_dir="/mnt/opensource-system/chirpstack-docker"

if [ -d "$docker_chirpstack_dir" ]; then
  echo "[INFO] 偵測到舊版 chirpstack-docker，進行移除..."
  if command -v docker >/dev/null 2>&1; then
    docker compose -f "$docker_chirpstack_dir/docker-compose.yml" down || true
  fi
  rm -rf "$docker_chirpstack_dir"
  echo "[OK] 舊版 chirpstack-docker 清除完成"
fi

# ───────────────────────────────────────────────
# Step 0: 安裝 Cron 任務與 Reverse SSH
# ───────────────────────────────────────────────
echo "[INFO] 設定 Cron 任務..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] Cron 任務設定失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Reverse SSH（遠端維運）..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] Reverse SSH 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 1: 移除舊 Linxdot/Watchcat 服務（如有）
# ───────────────────────────────────────────────
echo "[INFO] 移除舊服務..."
for svc in \
  linxdot-lora-pkt-fwd \
  linxdot-chripstack-service \
  linxdot_check \
  linxdot_setup \
  watchcat; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 停用並移除：$svc"
    /etc/init.d/$svc stop || true
    /etc/init.d/$svc disable || true
    rm -f "/etc/init.d/$svc"
  fi
done

# ───────────────────────────────────────────────
# Step 1.5: 清除 Relay 模式服務（避免混用）
# ───────────────────────────────────────────────
echo "[INFO] 檢查並移除 Relay 模式服務（若存在）..."
for svc in \
  linxdot_chirpstack_gateway_mesh_relay; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 偵測到 Relay 服務 $svc，執行停用與刪除..."
    /etc/init.d/$svc stop || true
    /etc/init.d/$svc disable || true
    rm -f "/etc/init.d/$svc"
  fi
done

# ───────────────────────────────────────────────
# Step 2: 安裝本地 ChirpStack Server（可選）
# ───────────────────────────────────────────────
echo "[INFO] 安裝 ChirpStack Server..."
/opt/awesome_linxdot/awesome_software/chirpstack_server/install_chirpstack_server.sh || {
  echo "[ERROR] ChirpStack Server 安裝失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Device Activator（設備註冊工具）..."
/opt/awesome_linxdot/awesome_software/chirpstack_device_activator/install_chirpstack_device_activator.sh || {
  echo "[ERROR] Device Activator 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 3: 安裝 SX1302 Concentratord
# ───────────────────────────────────────────────
echo "[INFO] 安裝 Concentratord..."
/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh || {
  echo "[ERROR] Concentratord 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 4: 安裝 UDP Forwarder
# ───────────────────────────────────────────────
echo "[INFO] 安裝 UDP Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh || {
  echo "[ERROR] UDP Forwarder 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 5: 安裝 Mesh Gateway（Border Beacon 模式）
# ───────────────────────────────────────────────
echo "[INFO] 安裝 Mesh Gateway（Border Beacon 模式）..."
/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh_border_beacon.sh || {
  echo "[ERROR] Mesh Gateway Border 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 6: 安裝 MQTT Forwarder（上傳至雲端）
# ───────────────────────────────────────────────
echo "[INFO] 安裝 MQTT Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install_chirpstack_mqtt_forwarder_as_border.sh || {
  echo "[ERROR] MQTT Forwarder 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 7: 設定所有服務為開機啟動
# ───────────────────────────────────────────────
for svc in \
  linxdot_chirpstack_concentratord \
  linxdot_chirpstack_udp_forwarder \
  linxdot_chirpstack_gateway_mesh_border \
  linxdot_chirpstack_mqtt_forwarder_as_border \
  chirpstack_device_activator; do

  if [ -f "/etc/init.d/$svc" ]; then
    /etc/init.d/$svc enable
  fi
done

# ───────────────────────────────────────────────
# Step 8: 顯示安裝服務狀態
# ───────────────────────────────────────────────
echo ""
echo "========== ✅ 安裝完成，服務狀態如下 =========="
for svc in \
  linxdot_chirpstack_concentratord \
  linxdot_chirpstack_udp_forwarder \
  linxdot_chirpstack_gateway_mesh_border \
  linxdot_chirpstack_mqtt_forwarder_as_border \
  chirpstack_device_activator; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] $svc:"
    /etc/init.d/$svc status || echo "  ⚠️ 尚未啟動"
  else
    echo "[WARN] $svc 尚未安裝"
  fi
done

# ───────────────────────────────────────────────
# 結尾說明
# ───────────────────────────────────────────────
echo ""
echo "✅ Linxdot Border Gateway 初始化完成！"
echo "[版本] v1.2.0"
echo "[時間] $(date +%F_%T)"
