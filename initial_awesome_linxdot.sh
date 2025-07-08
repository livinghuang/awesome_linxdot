#!/bin/sh

# initial awesome linxdot script

set -e
set -u


#install Cron Sync
echo "[INFO] 設定 Cron 任務同步..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] 設定 Cron 失敗" >&2
  exit 1
}

#install ChirpStack Device Activator
echo "[INFO] 安裝 ChirpStack Device Activator..."
/opt/awesome_linxdot/awesome_software/chirpstack_device_activator/install_chirpstack_device_activator.sh || {
  echo "[ERROR] 安裝 ChirpStack Device Activator 失敗" >&2
  exit 1
}

#install Reverse SSH
echo "[INFO] 安裝 Reverse SSH 服務..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] 安裝 Reverse SSH 失敗" >&2
  exit 1
}

# === 停用 lora_pkt_fwd（若存在） ===
if [ -f /etc/init.d/linxdot-lora-pkt-fwd ]; then
  echo "[INFO] 停用 lora_pkt_fwd..."
  /etc/init.d/linxdot-lora-pkt-fwd stop
  /etc/init.d/linxdot-lora-pkt-fwd disable
  rm /etc/init.d/linxdot-lora-pkt-fwd
fi

# === 停用舊的 ChirpStack Service ===
if [ -f /etc/init.d/linxdot-chripstack-service ]; then
  echo "[INFO] 停用舊的 Linxdot ChirpStack 服務..."
  /etc/init.d/linxdot-chripstack-service stop
  /etc/init.d/linxdot-chripstack-service disable
  rm /etc/init.d/linxdot-chripstack-service
fi

# === 停用 linxdot_check（若存在） ===
if [ -f /etc/init.d/linxdot_check ]; then
  echo "[INFO] 停用舊的 Linxdot Check 服務..."
  /etc/init.d/linxdot_check stop
  /etc/init.d/linxdot_check disable
  rm /etc/init.d/linxdot_check
fi

# === 停用 linxdot_setup 和 watchcat（若存在） ===
if [ -f /etc/init.d/linxdot_setup ]; then
  echo "[INFO] 停用舊的 Linxdot Setup 服務..."
  /etc/init.d/linxdot_setup stop
  /etc/init.d/linxdot_setup disable
  rm /etc/init.d/linxdot_setup
fi

if [ -f /etc/init.d/watchcat ]; then
  echo "[INFO] 停用 Watchcat..."
  /etc/init.d/watchcat stop
  /etc/init.d/watchcat disable
  rm /etc/init.d/watchcat
fi


#install local ChirpStack Server
echo "[INFO] 安裝本地 ChirpStack Server..."
/opt/awesome_linxdot/awesome_software/chirpstack_server/install_chirpstack_server.sh || {
  echo "[ERROR] 安裝本地 ChirpStack Server 失敗" >&2
  exit 1
}

# Default role is as 'gateway-mesh-border'
# ChirpStack Concentratord -> ChirpStack Gateway Mesh Border -> ChirpStack MQTT Forwarder

# Step 1: Install ChirpStack Concentratord
echo "[INFO] 安裝 ChirpStack Concentratord..."
/opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install_chirpstack_concentratord.sh || {
  echo "[ERROR] 安裝 ChirpStack Concentratord 失敗" >&2
  exit 1
}
# Step 2: Install ChirpStack Gateway Mesh Border
echo "[INFO] 安裝 ChirpStack Gateway Mesh Border..."
/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/install_chirpstack_gateway_mesh.sh border as923|| {
  echo "[ERROR] 安裝 ChirpStack Gateway Mesh Border 失敗" >&2
  exit 1
}
# # Step 3: Install ChirpStack MQTT Forwarder
# echo "[INFO] 安裝 ChirpStack MQTT Forwarder..."
# /opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install
# -chirpstack_mqtt_forwarder.sh || {
#   echo "[ERROR] 安裝 ChirpStack MQTT Forwarder 失敗" >&2
#   exit 1
# }
