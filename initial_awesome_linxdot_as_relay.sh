#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot OpenSource - 初始化安裝腳本（Relay 版）
# 功能：設定 Linxdot 為 Mesh Relay Gateway
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

set -e
set -u

echo "========== 🟡 Linxdot Relay Gateway 初始化開始 =========="

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
# Step 0: 安裝 Cron 與 Reverse SSH
# ───────────────────────────────────────────────

echo "[INFO] 設定 Cron 任務同步..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] 設定 Cron 失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Reverse SSH（供遠端管理維運）..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] 安裝 Reverse SSH 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 1: 停用舊的 Linxdot 與 Watchcat 服務
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
# Step 2: 安裝 ChirpStack Concentratord
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack Concentratord（SX1302 gateway driver）..."
/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh || {
  echo "[ERROR] 安裝 ChirpStack Concentratord 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 3: 安裝 ChirpStack UDP Forwarder（選擇性）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 UDP Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh || {
  echo "[ERROR] 安裝 ChirpStack UDP Forwarder 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 4: 安裝 ChirpStack Mesh Gateway（Relay 模式）
# ───────────────────────────────────────────────

echo "[INFO] 安裝 ChirpStack Mesh Gateway（Relay 模式）..."
/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh_relay.sh || {
  echo "[ERROR] 安裝 Mesh Gateway Relay 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# 結尾說明
# ───────────────────────────────────────────────

echo "✅ Linxdot Relay Gateway 初始化完成！"

# 架構摘要：
#   SX1302 → Concentratord
#          → Mesh Relay Gateway（轉送 Border 資料）
#          → UDP Forwarder（給 Local Server）
