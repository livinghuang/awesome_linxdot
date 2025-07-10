#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 初始化腳本（Multi-Server 模式）
# 功能：安裝 Linxdot 所需模組，資料同時轉送至本地與雲端 ChirpStack Server
# 適用：LoRaWAN Border Gateway（不含 Mesh Beacon）
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

set -e
set -u

echo "========== Linxdot Multi-Server Gateway 初始化開始 =========="
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
# Step 0: 安裝 Cron 與 Reverse SSH（維運功能）
# ───────────────────────────────────────────────

echo "[INFO] 同步 Cron 任務..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] Cron 設定失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Reverse SSH..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] Reverse SSH 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 1: 停用 Linxdot 舊版與 Watchcat 等背景服務
# ───────────────────────────────────────────────

for svc in \
  linxdot-lora-pkt-fwd \
  linxdot-chripstack-service \
  linxdot_check \
  linxdot_setup \
  watchcat; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 停用舊服務：$svc"
    /etc/init.d/$svc stop || true
    /etc/init.d/$svc disable || true
    rm -f "/etc/init.d/$svc"
  fi
done

# ───────────────────────────────────────────────
# Step 2: 安裝本地 ChirpStack Server（可依需求保留）
# ───────────────────────────────────────────────

echo "[INFO] 安裝本地 ChirpStack Server..."
/opt/awesome_linxdot/awesome_software/chirpstack_server/install_chirpstack_server.sh || {
  echo "[ERROR] 本地 ChirpStack Server 安裝失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Device Activator..."
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
# Step 4: 安裝 UDP Forwarder（往 Local Server）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 UDP Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh || {
  echo "[ERROR] UDP Forwarder 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 5: 安裝 MQTT Forwarder（往 Cloud Server）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 MQTT Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install_chirpstack_mqtt_forwarder.sh || {
  echo "[ERROR] MQTT Forwarder 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# 完成說明
# ───────────────────────────────────────────────

echo "✅ Linxdot Multi-Server 初始化完成！"

echo ""
echo "📡 Gateway 資料流："
echo "  SX1302 → Concentratord"
echo "         ├→ UDP Forwarder → Local ChirpStack"
echo "         └→ MQTT Forwarder → Cloud ChirpStack"
echo ""
