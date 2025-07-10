#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 初始化腳本（Border Gateway）
# 功能：設定 Linxdot 為 LoRa Mesh Border Gateway，並連線至遠端 ChirpStack Cloud Server
# Author: Living Huang
# Updated: 2025-07-10
# 適用設備：Linxdot（OpenWrt, SX1302, Docker, MQTT 支援）
# ───────────────────────────────────────────────

set -e  # 發生任何錯誤即中斷執行
set -u  # 使用未定義變數即報錯

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
# Step 0: 安裝 Cron 任務與 Reverse SSH 功能（雲端遠控與定期任務）
# ───────────────────────────────────────────────

echo "[INFO] 同步 Cron 任務..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] Cron 任務設定失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Reverse SSH（供遠端管理維運）..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] Reverse SSH 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 1: 停用與移除過去預設舊服務（避免干擾新系統）
# ───────────────────────────────────────────────

echo "[INFO] 移除過往服務..."
for svc in \
  linxdot-lora-pkt-fwd \
  linxdot-chripstack-service \
  linxdot_check \
  linxdot_setup \
  watchcat; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 停用並移除服務：$svc"
    /etc/init.d/$svc stop || true
    /etc/init.d/$svc disable || true
    rm -f "/etc/init.d/$svc"
  fi
done

# ───────────────────────────────────────────────
# Step 2: 安裝本地 ChirpStack Server（管理設備與資料）
# 僅用於 Border Gateway 具備本地處理能力的情境（可選）
# ───────────────────────────────────────────────

echo "[INFO] 安裝本地 ChirpStack Server..."
/opt/awesome_linxdot/awesome_software/chirpstack_server/install_chirpstack_server.sh || {
  echo "[ERROR] ChirpStack Server 安裝失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Device Activator（設備快速註冊工具）..."
/opt/awesome_linxdot/awesome_software/chirpstack_device_activator/install_chirpstack_device_activator.sh || {
  echo "[ERROR] Device Activator 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 3: 安裝 SX1302 Concentratord（LoRa 實體接收）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack Concentratord（SX1302 gateway driver）..."
/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh || {
  echo "[ERROR] Concentratord 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 4: 安裝 ChirpStack UDP Forwarder（將封包送至 Server 或 Mesh Gateway）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 UDP Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh || {
  echo "[ERROR] UDP Forwarder 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 5: 安裝 Mesh Gateway（Border Beacon 模式）
# 功能：定時送出心跳封包與時間同步（給 Relay Gateways 使用）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack Mesh Gateway（Border Beacon 模式）..."
/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh_border_beacon.sh || {
  echo "[ERROR] Mesh Gateway Border Beacon 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 6: 安裝 MQTT Forwarder（將封包轉送至雲端 MQTT Broker）
# 功能：作為 LoRa → MQTT Cloud Gateway 使用
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack MQTT Forwarder（作為 Border 模式）..."
/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install_chirpstack_mqtt_forwarder_as_border.sh || {
  echo "[ERROR] MQTT Forwarder 安裝失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# 最終提示
# ───────────────────────────────────────────────

echo "✅ Linxdot Border Gateway 初始化完成！"
echo ""
echo "📡 組成路徑："
echo "  SX1302 → concentratord"
echo "         └→ UDP Forwarder（給 Local Server）"
echo "         └→ Mesh Gateway（給 Relay）"
echo "         └→ MQTT Forwarder（給 Cloud Broker）"
echo ""
