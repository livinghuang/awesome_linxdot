#!/bin/sh

# initial awesome linxdot script

#install Cron Sync
echo "[INFO] 設定 Cron 任務同步..."
/opt/awesome_linxdot/awesome_software/cron/cron_sync.sh || {
  echo "[ERROR] 設定 Cron 失敗" >&2
  exit 1
}

#install ChirpStack Device Activator
echo "[INFO] 安裝 ChirpStack Device Activator..."
/opt/awesome_linxdot/awesome_software/chirpstack_device_activator/install-chirpstack_device_activator.sh || {
  echo "[ERROR] 安裝 ChirpStack Device Activator 失敗" >&2
  exit 1
}

#install Reverse SSH
echo "[INFO] 安裝 Reverse SSH 服務..."
/opt/awesome_linxdot/awesome_software/reverse_ssh/install_reverse_ssh.sh || {
  echo "[ERROR] 安裝 Reverse SSH 失敗" >&2
  exit 1
}

#stop and disable lora_pkt_fwd
# This is necessary to avoid conflicts with the new ChirpStack Concentrator
echo "[INFO] 停用 lora_pkt_fwd..."
/etc/init.d/linxdot-lora-pkt-fwd stop
/etc/init.d/linxdot-lora-pkt-fwd disable

#stop and disable old linxdot ChirpStack Service
# This is necessary to avoid conflicts with the new ChirpStack Service
echo "[INFO] 停用舊的 Linxdot ChirpStack 服務..."
/etc/init.d/linxdot-chripstack-service stop
/etc/init.d/linxdot-chripstack-service disable

#stop and disable old linxdot check service(it is for miner)
echo "[INFO] 停用舊的 Linxdot Check 服務..."
/etc/init.d/linxdot_check stop
/etc/init.d/linxdot_check disable

#stop and disable old linxdot setup and watchcat service
echo "[INFO] 停用舊的 Linxdot Setup 和 Watchcat 服務..."
/etc/init.d/linxdot_setup stop
/etc/init.d/linxdot_setup disable
/etc/init.d/linxdot_watchcat stop
/etc/init.d/linxdot_watchcat disable


# #install local ChirpStack Server
# echo "[INFO] 安裝本地 ChirpStack Server..."
# /opt/awesome_linxdot/awesome_software/chirpstack_server/install-chirpstack_server.sh || {
#   echo "[ERROR] 安裝本地 ChirpStack Server 失敗" >&2
#   exit 1
# }

# # Default role is as 'gateway-mesh-border'
# # ChirpStack Concentratord -> ChirpStack Gateway Mesh Border -> ChirpStack MQTT Forwarder

# # Step 1: Install ChirpStack Concentratord
# echo "[INFO] 安裝 ChirpStack Concentratord..."
# /opt/awesome_linxdot/awesome_software/chirpstack_concentratord/install-chirpstack_concentratord.sh || {
#   echo "[ERROR] 安裝 ChirpStack Concentratord 失敗" >&2
#   exit 1
# }
# # Step 2: Install ChirpStack Gateway Mesh Border
# echo "[INFO] 安裝 ChirpStack Gateway Mesh Border..."
# /opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh_border/install-chirpstack_gateway_mesh_border.sh || {
#   echo "[ERROR] 安裝 ChirpStack Gateway Mesh Border 失敗" >&2
#   exit 1
# }
# # Step 3: Install ChirpStack MQTT Forwarder
# echo "[INFO] 安裝 ChirpStack MQTT Forwarder..."
# /opt/awesome_linxdot/awesome_software/chirpstack_mqtt_forwarder/install
# -chirpstack_mqtt_forwarder.sh || {
#   echo "[ERROR] 安裝 ChirpStack MQTT Forwarder 失敗" >&2
#   exit 1
# }
