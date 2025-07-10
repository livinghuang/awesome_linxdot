#!/bin/sh

# ───────────────────────────────────────────────
# 移除 Linxdot UDP Forwarder 與相關檔案
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

echo "【1】停止並關閉服務..."
/etc/init.d/linxdot_chirpstack_udp_forwarder stop
/etc/init.d/linxdot_chirpstack_udp_forwarder disable

echo "【2】移除 init.d 服務檔案..."
rm -f /etc/init.d/linxdot_chirpstack_udp_forwarder

echo "【3】移除執行檔與設定..."
rm -rf /opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder_sx1302

echo "✅ UDP Forwarder 移除完成。"
