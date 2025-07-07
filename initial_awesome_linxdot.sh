#!/bin/sh

# initial awesome linxdot script

echo "[INFO] 設定 Cron 任務同步..."
/opt/awesome_linxdot/awesome-software/cron/cron_sync.sh || {
  echo "[ERROR] 設定 Cron 失敗" >&2
  exit 1
}

echo "[INFO] 安裝 ChirpStack Device Activator..."
/opt/awesome_linxdot/awesome-software/chirpstack_device_activator/install-chirpstack_device_activator.sh || {
  echo "[ERROR] 安裝 ChirpStack Device Activator 失敗" >&2
  exit 1
}

echo "[INFO] 安裝 Reverse SSH 服務..."
/opt/awesome_linxdot/awesome-software/reverse_ssh/install-reverse_ssh.sh || {
  echo "[ERROR] 安裝 Reverse SSH 失敗" >&2
  exit 1
}

echo "[INFO] 停用 lora_pkt_fwd..."
/etc/init.d/linxdot-lora-pkt-fwd stop
/etc/init.d/linxdot-lora-pkt-fwd disable
