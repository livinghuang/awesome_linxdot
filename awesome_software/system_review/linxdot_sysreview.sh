#!/bin/sh
# Linxdot / OpenWrt 系統健檢報告 (BusyBox-friendly v1.3)
set -eu
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

TS="$(date +%Y%m%d_%H%M%S)"
OUT="/root/linxdot_health_$TS"
mkdir -p "$OUT"

# ---- helper ----
print_swap() {
  echo "=== SWAP ==="
  if [ -f /proc/swaps ] && [ "$(wc -l </proc/swaps)" -gt 1 ]; then
    cat /proc/swaps
  else
    awk '/^SwapTotal|^SwapFree|^SwapCached/ {print}' /proc/meminfo
  fi
}

print_inode_summary() {
  echo "=== INODE (kernel global) ==="
  if [ -r /proc/sys/fs/inode-nr ]; then
    # /proc/sys/fs/inode-nr: nr free
    read NR FREE < /proc/sys/fs/inode-nr || true
    echo "nr_inodes: ${NR:-N/A}"
    echo "free_inodes: ${FREE:-N/A}"
  else
    echo "N/A"
  fi
  echo "=== FILESYSTEM TYPE (/) ==="
  df -T / 2>/dev/null || echo "N/A"
}

print_dmesg_warn() {
  echo "=== dmesg (error/warn) ==="
  dmesg 2>/dev/null | grep -iE "error|warn|fail|oom|crash" || true
}

print_listen_ports() {
  echo "=== LISTEN PORTS (22/80/443) ==="
  if command -v netstat >/dev/null 2>&1; then
    netstat -ltnp 2>/dev/null | grep -E ':(22|80|443)\s' || true
  elif command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | grep -E ':(22|80|443)\s' || true
  else
    echo "netstat/ss 不可用"
  fi
}

# ---- 00 基本 ----
{
  echo "=== MODEL ==="; tr -d '\0' </proc/device-tree/model 2>/dev/null || true
  echo; echo "=== UNAME ==="; uname -a
  echo; echo "=== UPTIME ==="; uptime
  echo; echo "=== TEMP ==="
  [ -f /sys/class/thermal/thermal_zone0/temp ] \
    && awk '{printf "CPU temp: %.1f°C\n",$1/1000}' /sys/class/thermal/thermal_zone0/temp \
    || echo "N/A"
} > "$OUT/00_basic.txt"

# ---- 10 資源 ----
{
  echo "=== MEMORY ==="; free -h
  print_swap
  echo; echo "=== DISK (df -h /) ==="; df -h /
  print_inode_summary
  echo; echo "=== MOUNT OVERLAY ==="
  mount | grep -E ' on / type overlay|/overlay' || true
} > "$OUT/10_resource.txt"

# ---- 20 網路與時間 ----
{
  echo "=== IP ==="; ip -4 a
  echo; echo "=== ROUTE ==="; ip r
  echo; echo "=== RESOLV ==="; cat /etc/resolv.conf
  echo; echo "=== TIME ==="; date -R
  echo; echo "=== NTP STATUS ==="
  (/etc/init.d/sysntpd status || /etc/init.d/chronyd status) 2>/dev/null || echo "N/A"
  echo; echo "=== PING GW ==="
  GW=$(ip r | awk '/default/ {print $3; exit}'); [ -n "${GW:-}" ] && ping -c2 "$GW" || true
  echo; echo "=== PING 1.1.1.1 ==="; ping -c2 1.1.1.1 || true
  echo; echo "=== PING google.com ==="; ping -c2 google.com || true
} > "$OUT/20_network_time.txt"

# ---- 30 服務 & cron ----
{
  echo "=== SERVICES ==="
  for s in network dnsmasq sysntpd chronyd dockerd uhttpd dropbear \
           linxdot_chirpstack_concentratord \
           linxdot_chirpstack_gateway_mesh_border \
           linxdot_chirpstack_mqtt_forwarder_as_border \
           linxdot_chirpstack_udp_forwarder \
           linxdot_chirpstack_service; do
    [ -x "/etc/init.d/$s" ] && echo "-- $s --" && /etc/init.d/$s status || true
  done
  echo; echo "=== CRONTAB (root) ==="
  [ -f /etc/crontabs/root ] && sed -n '1,200p' /etc/crontabs/root || echo "no /etc/crontabs/root"
  echo; echo "=== CRON LOG (last 100) ==="
  # BusyBox 相容：不用 -n，改 tail+grep
  (logread 2>/dev/null | grep -i crond | tail -n 100) || true
} > "$OUT/30_services_cron.txt"

# ---- 40 Docker ----
{
  echo "=== DOCKER INFO ==="
  (docker --version || true)
  (docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' || docker ps || true)
  echo; echo "=== DOCKER DF ==="; docker system df || true
  echo; echo "=== LOGGING DRIVER ==="
  docker info 2>/dev/null | awk -F': ' '/Logging Driver/ {print $0}' || true
} > "$OUT/40_docker.txt"

# ---- 50 LoRa / SX1302 / Concentratord ----
{
  echo "=== CONCENTRATORD STATUS ==="
  /etc/init.d/linxdot_chirpstack_concentratord status 2>/dev/null || echo "N/A"
  echo; echo "=== GREP LOG (concentratord|sx1302|SPI|radio|gateway|mesh) ==="
  # BusyBox 相容：先 tail 再 grep，避免 log 很大
  (logread 2>/dev/null | tail -n 2000 | grep -Ei 'concentratord|sx1302|SPI|radio|gateway|mesh') || true
  echo; echo "=== CONF PATHS ==="
  ls -l /etc/chirpstack-concentratord* 2>/dev/null || true
  ls -l /tmp 2>/dev/null | grep -E 'concentrator|concentratord|stats|gateway' || true
} > "$OUT/50_lora.txt"

# ---- 60 日誌 ----
{
  print_dmesg_warn
  echo; echo "=== logread ERR/WARN (last 300) ==="
  # BusyBox 相容：tail 2000 後再 grep，再取最後 300 行
  (logread 2>/dev/null | tail -n 2000 | grep -Ei "error|warn|fail|oom|crash" | tail -n 300) || true
} > "$OUT/60_logs.txt"

# ---- 70 安全 ----
{
  print_listen_ports
  echo; echo "=== FIREWALL (brief) ==="
  uci show firewall 2>/dev/null | grep -E '(^firewall\.|\.input=|\.forward=|\.output=|\.src=wan)' || true
  echo; echo "=== SSH KEYS ==="
  ls -l /root/.ssh/authorized_keys 2>/dev/null || true
} > "$OUT/70_security.txt"

# ---- 打包 ----
TAR="/root/linxdot_health_${TS}.tar.gz"
tar -C "$(dirname "$OUT")" -czf "$TAR" "$(basename "$OUT")"
echo "Report ready: $TAR"
