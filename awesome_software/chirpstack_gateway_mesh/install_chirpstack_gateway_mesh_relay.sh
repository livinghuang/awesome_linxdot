#!/bin/sh

# ───────────────────────────────────────────────
# 安裝 ChirpStack Mesh Gateway - Border Beacon 版本
# Author: Living Huang
# Date: 2025-07-10
# ───────────────────────────────────────────────

binary="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/chirpstack_gateway_mesh_border_beacon"
config="/opt/awesome_linxdot/awesome_software/chirpstack_gateway_mesh/chirpstack_gateway_mesh_binary/config/chirpstack_gateway_mesh_as_border.toml"
initd_file="/etc/init.d/linxdot_chirpstack_gateway_mesh_border_beacon"

echo "[INFO] 安裝 ChirpStack Mesh Border Beacon Service..."

cat << EOF > "$initd_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
  logger -t "mesh_border_beacon" "啟動 ChirpStack Mesh Border Beacon"
  procd_open_instance
  procd_set_param command "$binary" -c "$config"
  procd_set_param respawn 3600 5 0
  procd_set_param stdout 1
  procd_set_param stderr 1
  procd_close_instance
}

stop_service() {
  logger -t "mesh_border_beacon" "停止 ChirpStack Mesh Border Beacon"
}
EOF

chmod +x "$initd_file"
"$initd_file" enable
"$initd_file" start
echo "[INFO] 安裝完成並已啟動！"
