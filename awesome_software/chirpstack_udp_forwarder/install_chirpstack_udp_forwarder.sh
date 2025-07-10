#!/bin/sh

# ───────────────────────────────────────────────
# Linxdot UDP Forwarder Installer
# 安裝 chirpstack_udp_forwarder 為 OpenWrt 背景服務
# 適用機種：Linxdot + SX1302 + OpenWrt
# Author: Living Huang
# Updated: 2025-07-10
# ───────────────────────────────────────────────

# 安裝目標目錄
base_dir="/opt/awesome_linxdot/chirpstack_software/chirpstack_udp_forwarder_sx1302"
run_script="/opt/awesome_linxdot/run_chirpstack_udp_forwarder.sh"
initd_dst="/etc/init.d/linxdot_chirpstack_udp_forwarder"
initd_src="./chirpstack_udp_forwarder.initd"

echo "【1】建立目錄結構：$base_dir"
mkdir -p "$base_dir"

echo "【2】複製 binary 與設定檔..."
cp chirpstack_udp_forwarder_binary/chirpstack_udp_forwarder "$base_dir/"
cp chirpstack_udp_forwarder_binary/chirpstack_udp_forwarder.toml "$base_dir/"
chmod +x "$base_dir/chirpstack_udp_forwarder"

echo "【3】建立啟動腳本（run_chirpstack_udp_forwarder.sh）..."
cat <<EOF > "$run_script"
#!/bin/sh
# 此腳本由 procd 執行，不需 loop，只需一次啟動 forwarder

logger -t "chirpstack_udp_forwarder" "Starting UDP forwarder..."
exec $base_dir/chirpstack_udp_forwarder -c $base_dir/chirpstack_udp_forwarder.toml
EOF

chmod +x "$run_script"

echo "【4】安裝 init.d 服務腳本..."
cp "$initd_src" "$initd_dst"
chmod +x "$initd_dst"

echo "【5】設定開機自動啟動並立即啟動..."
"$initd_dst" enable
"$initd_dst" start

echo "✅ 安裝完成。"
