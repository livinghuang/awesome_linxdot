#!/bin/sh

# ───────────────────────────────────────────────
# 安裝腳本：ChirpStack UDP Forwarder (Linxdot)
# 不使用 run script，直接透過 init.d 控制 binary
# 路徑基於：/opt/awesome_linxdot/awesome_software
# ───────────────────────────────────────────────

base_dir="/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/chirpstack_udp_forwarder_binary"
initd_src="/opt/awesome_linxdot/awesome_software/chirpstack_udp_forwarder/chirpstack_udp_forwarder.initd"
initd_dst="/etc/init.d/linxdot_chirpstack_udp_forwarder"

echo "【1】確認 binary 與 config 存在..."
if [ ! -f "$base_dir/chirpstack_udp_forwarder" ] || [ ! -f "$base_dir/chirpstack_udp_forwarder.toml" ]; then
    echo "[ERROR] 找不到執行檔或設定檔，請確認 binary 是否編譯好。" >&2
    exit 1
fi
chmod +x "$base_dir/chirpstack_udp_forwarder"

echo "【2】安裝 init.d 服務腳本..."
cp "$initd_src" "$initd_dst"
chmod +x "$initd_dst"

echo "【3】啟用與啟動服務..."
"$initd_dst" enable
"$initd_dst" start

echo "✅ ChirpStack UDP Forwarder 安裝完成。"
