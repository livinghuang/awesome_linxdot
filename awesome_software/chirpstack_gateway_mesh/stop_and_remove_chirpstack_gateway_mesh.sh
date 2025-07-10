#!/bin/sh

# Linxdot OpenSource
# 移除所有 ChirpStack Gateway Mesh 服務（border / relay / beacon）
# Author: Living Huang
# Date: 2025-07-10

SERVICES="linxdot_chirpstack_gateway_mesh_border linxdot_chirpstack_gateway_mesh_relay"

echo "[INFO] 停用並移除 Gateway Mesh 相關服務..."

for svc in $SERVICES; do
  if [ -f "/etc/init.d/$svc" ]; then
    echo "[INFO] 停用服務 $svc"
    /etc/init.d/$svc stop
    /etc/init.d/$svc disable
    rm -f /etc/init.d/$svc
    echo "[OK] 已移除服務 $svc"
  else
    echo "[WARN] 服務 $svc 不存在，略過..."
  fi
done

echo "[DONE] 所有 Gateway Mesh 服務已停用並清除"
