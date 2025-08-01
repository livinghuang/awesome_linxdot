#!/bin/sh

###############################################################################
# Linxdot OpenSource - 初始化安裝腳本（Relay 版）
# 功能：設定 Linxdot 為 Mesh Relay Gateway
# Author: Living Huang
# Version: v1.2.0
# Updated: 2025-08-01
###############################################################################

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
# Step 1: 停用舊的 Linxdot 服務與 Watchcat
# ───────────────────────────────────────────────
for svc in \
  linxdot-lora-pkt-fwd \
  linxdot-chripstack-service \
  linxdot_check \
  linxdot_setup \
  watchcat; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 停用並移除舊服務：$svc"
    /etc/init.d/$svc stop || true
    /etc/init.d/$svc disable || true
    rm -f "/etc/init.d/$svc"
  fi
done

# ───────────────────────────────────────────────
# Step 2: 安裝 ChirpStack Concentratord
# ───────────────────────────────────────────────
echo "[INFO] 安裝 ChirpStack Concentratord（SX1302 gateway driver）..."
/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh || {
  echo "[ERROR] 安裝 Concentratord 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 3: 安裝 ChirpStack UDP Forwarder（選用）
# ───────────────────────────────────────────────
echo "[INFO] 安裝 UDP Forwarder..."
/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh || {
  echo "[ERROR] 安裝 UDP Forwarder 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 3.5: 清除 Border 模式服務（如有）
# ───────────────────────────────────────────────
echo "[INFO] 檢查並移除 Border 模式相關服務（若存在）..."
for svc in \
  linxdot_chirpstack_gateway_mesh_border \
  linxdot_chirpstack_mqtt_forwarder_as_border; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 移除 Border 服務：$svc"
    /etc/init.d/$svc stop || true
    /etc/init.d/$svc disable || true
    rm -f "/etc/init.d/$svc"
  fi
done

# ───────────────────────────────────────────────
# Step 4: 安裝 Mesh Gateway（Relay 模式）
# ───────────────────────────────────────────────
echo "[INFO] 安裝 Mesh Gateway Relay 模組..."
/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh_relay.sh || {
  echo "[ERROR] 安裝 Mesh Gateway Relay 失敗" >&2
  exit 1
}

# ───────────────────────────────────────────────
# Step 5: 設定服務為開機啟動
# ───────────────────────────────────────────────
for svc in \
  linxdot_chirpstack_concentratord \
  linxdot_chirpstack_gateway_mesh_relay \
  linxdot_chirpstack_udp_forwarder; do
  if [ -f "/etc/init.d/$svc" ]; then
    /etc/init.d/$svc enable
  fi
done

# ───────────────────────────────────────────────
# Step 6: 顯示服務執行狀態
# ───────────────────────────────────────────────
echo ""
echo "========== ✅ 安裝完成，服務狀態如下 =========="
for svc in \
  linxdot_chirpstack_concentratord \
  linxdot_chirpstack_gateway_mesh_relay \
  linxdot_chirpstack_udp_forwarder; do

  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] $svc:"
    /etc/init.d/$svc status || echo "  ⚠️ 尚未啟動"
  else
    echo "[WARN] $svc 尚未安裝"
  fi
done

# ───────────────────────────────────────────────
# 結尾：版本資訊與結語
# ───────────────────────────────────────────────
echo ""
echo "✅ Linxdot Relay Gateway 初始化完成！"
echo "[版本] v1.2.0"
echo "[時間] $(date +%F_%T)"
