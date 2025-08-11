#!/bin/sh
###############################################################################
# Linxdot OpenSource - 初始化安裝腳本：Border 專用
# 目標：切換到「LoRa Mesh Border」，並連線至遠端 ChirpStack Cloud
# 特色：先徹底清掉 All-in-one(Docker) / Multi-Server / Relay，避免 1700/1883/3001 埠衝突
# Author: Living Huang (revised)
# Version: v1.3.1
# Updated: 2025-08-11
###############################################################################
set -eu
PATH=/bin:/sbin:/usr/bin:/usr/sbin

say()  { printf '%b\n' "$*"; }
ok()   { say "✅ $*"; }
warn() { say "⚠️  $*"; }
err()  { say "❌ $*"; }
hr()   { say "------------------------------------------------------------"; }

# === 可調參數（可用環境變數覆寫） ===
DOCKER_CHIRP_DIR="${DOCKER_CHIRP_DIR:-/mnt/opensource-system/chirpstack-docker}"
PURGE_IMAGES="${PURGE_IMAGES:-0}"       # 1: 連 AIO 鏡像也清
PURGE_VOLUMES="${PURGE_VOLUMES:-1}"     # 1: 清 AIO volumes
PURGE_NETWORKS="${PURGE_NETWORKS:-1}"   # 1: 清常見 networks
CRON_PURGE="${CRON_PURGE:-1}"           # 1: 從 root crontab 移除 multi-server 相關排程

# 判定 AIO/Multi-Server 用的影像關鍵字
AIO_IMAGE_KEYS='chirpstack/chirpstack|chirpstack/chirpstack-gateway-bridge|eclipse-mosquitto|redis|postgres|chirpstack/chirpstack-rest-api'

# Border 需要啟用的服務（順序）
BORDER_SERVICES_ENABLE="
linxdot_chirpstack_concentratord
linxdot_chirpstack_udp_forwarder
linxdot_chirpstack_gateway_mesh_border
linxdot_chirpstack_mqtt_forwarder_as_border
chirpstack_device_activator
"

# 需停用/移除的舊或不相容服務（含 Relay / Multi-Server / 舊名）
OTHER_ROLE_SERVICES="
linxdot_chirpstack_gateway_mesh_relay
linxdot_chirpstack_mqtt_forwarder_as_relay
linxdot_multi_server
linxdot_chirpstack_service
linxdot-lora-pkt-fwd
linxdot-chripstack-service
linxdot_check
linxdot_setup
watchcat
"

docker_present=0
command -v docker >/dev/null 2>&1 && docker_present=1

# ---------- Docker 清理 ----------
stop_rm_aio_containers() {
  [ "$docker_present" -eq 1 ] || return 0
  say "[INFO] 移除 All-in-one / Multi-Server 容器..."
  docker ps -a --format '{{.ID}}\t{{.Image}}\t{{.Names}}' 2>/dev/null \
    | grep -E "$AIO_IMAGE_KEYS" 2>/dev/null \
    | while IFS="$(printf '\t')" read -r id img name; do
        say "  - remove container: $name ($img)"
        docker rm -f "$name" >/dev/null 2>&1 || true
      done
}

rm_aio_networks() {
  [ "$docker_present" -eq 1 ] || return 0
  [ "$PURGE_NETWORKS" -eq 1 ] || return 0
  say "[INFO] 清除 docker networks（chirpstack_default/chirpnet 若存在）..."
  for net in chirpstack_default chirpnet; do
    docker network rm "$net" >/dev/null 2>&1 || true
  done
}

rm_aio_volumes() {
  [ "$docker_present" -eq 1 ] || return 0
  [ "$PURGE_VOLUMES" -eq 1 ] || return 0
  say "[INFO] 清除 AIO 相關 volumes（postgres/redis/mosquitto/chirpstack）..."
  docker volume ls -q 2>/dev/null \
    | grep -Ei 'chirp|mosquitto|redis|postgres' 2>/dev/null \
    | xargs -r docker volume rm -f >/dev/null 2>&1 || true
}

rm_aio_images() {
  [ "$docker_present" -eq 1 ] || return 0
  [ "$PURGE_IMAGES" -eq 1 ] || return 0
  say "[INFO] 清除 AIO 相關鏡像（PURGE_IMAGES=1 才會執行）..."
  docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' 2>/dev/null \
    | grep -E "$AIO_IMAGE_KEYS" 2>/dev/null \
    | awk '{print $2}' \
    | xargs -r docker rmi -f >/dev/null 2>&1 || true
}

free_conflicting_ports() {
  say "[INFO] 檢查目前埠位佔用（1700/1883/3001）..."
  (netstat -lpun 2>/dev/null || ss -lunp 2>/dev/null) | grep -E ':(1700|1883|3001)\b' || true
}

# ---------- init.d 與 cron 清理 ----------
stop_disable_remove_service() {
  svc="$1"
  if [ -f "/etc/init.d/$svc" ]; then
    /etc/init.d/$svc stop >/dev/null 2>&1 || true
    /etc/init.d/$svc disable >/dev/null 2>&1 || true
    rm -f "/etc/init.d/$svc" || true
    say "  - removed $svc"
  fi
}

purge_other_roles() {
  say "[INFO] 停用/移除其它角色服務（Relay / Multi-Server / 舊名）..."
  for s in $OTHER_ROLE_SERVICES; do
    stop_disable_remove_service "$s"
  done

  # 補殺殘留行程（保守）
  pgrep -fa chirpstack 2>/dev/null | grep -Ei 'server|bridge|postgres|redis|mosquitto' \
    | awk '{print $1}' | xargs -r kill -9 2>/dev/null || true

  # 清 cron 內與 multi-server / chirpstack_service 相關的自動啟動
  if [ "$CRON_PURGE" -eq 1 ] && [ -f /etc/crontabs/root ]; then
    cp /etc/crontabs/root /etc/crontabs/root.bak.$(date +%Y%m%d%H%M%S) || true
    sed -i -e '/chirpstack_service/d' -e '/multi[ -_]*server/d' /etc/crontabs/root
    /etc/init.d/cron restart >/dev/null 2>&1 || true
    say "  - purged crontab entries (multi-server/chirpstack_service)"
  fi
}

# ---------- 安裝流程 ----------
run_or_die() {
  sh -c "$1" || { err "$2"; exit 1; }
}

install_cron_and_rssh() {
  say "[INFO] 設定 Cron 任務..."
  run_or_die "/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh" "[ERROR] Cron 任務設定失敗"

  say "[INFO] 安裝 Reverse SSH（遠端維運）..."
  run_or_die "/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh" "[ERROR] Reverse SSH 安裝失敗"
}

install_border_stack() {
  say "[INFO] 安裝 SX1302 Concentratord..."
  run_or_die "/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh" "[ERROR] Concentratord 安裝失敗"

  say "[INFO] 安裝 UDP Forwarder..."
  run_or_die "/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/install_chirpstack_udp_forwarder.sh" "[ERROR] UDP Forwarder 安裝失敗"

  say "[INFO] 安裝 Mesh Gateway（Border Beacon 模式）..."
  run_or_die "/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh_border_beacon.sh" "[ERROR] Mesh Gateway Border 安裝失敗"

  say "[INFO] 安裝 MQTT Forwarder（上傳至雲端）..."
  run_or_die "/opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install_chirpstack_mqtt_forwarder_as_border.sh" "[ERROR] MQTT Forwarder 安裝失敗"

  say "[INFO] 安裝 Device Activator（設備註冊工具）..."
  run_or_die "/opt/awesome_linxdot/awesome_software/chirpstack_device_activator/install_chirpstack_device_activator.sh" "[ERROR] Device Activator 安裝失敗"
}

enable_border_services() {
  say "[INFO] 設定服務為開機自動啟動..."
  for s in $BORDER_SERVICES_ENABLE; do
    [ -f "/etc/init.d/$s" ] && /etc/init.d/$s enable >/dev/null 2>&1 || true
  done
}

show_services_status() {
  echo ""
  say "========== ✅ 安裝完成，服務狀態如下 =========="
  for s in $BORDER_SERVICES_ENABLE; do
    if [ -f "/etc/init.d/$s" ]; then
      echo "[INFO] $s:"
      /etc/init.d/$s status || say "  ⚠️ 尚未啟動"
    else
      warn "$s 尚未安裝"
    fi
  done
}

# ===================== 主流程 =====================
say "========== 🟢 Linxdot Border Gateway 初始化開始 =========="

# 0) 移除舊 compose 專案目錄（若存在）
if [ -d "$DOCKER_CHIRP_DIR" ]; then
  say "[INFO] 偵測到舊版 chirpstack-docker 專案目錄，移除中..."
  rm -rf "$DOCKER_CHIRP_DIR" || true
  ok "舊版 chirpstack-docker 清除完成"
fi

# A) 清理 All‑in‑one / Multi-Server（容器→網路→卷→鏡像）
if [ "$docker_present" -eq 1 ]; then
  hr
  say "[STEP] 清理 All-in-one / Multi-Server（Docker）"
  stop_rm_aio_containers
  rm_aio_networks
  rm_aio_volumes
  rm_aio_images
else
  warn "docker 不存在，略過 AIO 清理"
fi

# B) 清理其它角色與自動拉起
hr
say "[STEP] 清除其它角色服務與自動啟動"
purge_other_roles
free_conflicting_ports

# C) 安裝 Cron 與 Reverse SSH
hr
say "[STEP] 安裝基礎維運（Cron / Reverse SSH）"
install_cron_and_rssh

# D) 安裝 Border 元件
hr
say "[STEP] 安裝 Border 元件"
install_border_stack

# E) 設為開機自動
hr
say "[STEP] 啟用 Border 服務自動啟動"
enable_border_services

# F) 顯示狀態
hr
show_services_status

echo ""
ok "Linxdot Border Gateway 初始化完成！"
say "[版本] v1.3.1"
say "[時間] $(date +%F_%T)"
