#!/bin/sh
# Linxdot Login Summary (OpenWrt/BusyBox friendly)
# v1.0  — modes: table (default), --short, --json
# exit codes: 0=OK, 1=Unknown role, 2=Docker problem, 3=Role conflict
# tip: set in /etc/profile.d to auto-run `--short` on SSH login

set -eu
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

MODE="table"
[ "${1:-}" = "--short" ] && MODE="short"
[ "${1:-}" = "--json" ]  && MODE="json"

# ---------- helpers ----------
yn()      { [ "$1" -eq 1 ] && echo yes || echo no; }
yn_json() { [ "$1" -eq 1 ] && echo true || echo false; }
has()     { command -v "$1" >/dev/null 2>&1; }
now()     { date -R; }
log_last() {
  # 從 syslog 擷取最後一條相關訊息的時間（近似）
  # BusyBox logread 無 -n / -t，改用 tail | grep
  logread 2>/dev/null | tail -n 2000 | grep -iE "$1" | tail -n 1 \
    | sed -E 's/^([A-Z][a-z]{2} [A-Z][a-z]{2} [ 0-9]{1,2} [0-9:]{8}).*/\1/' 2>/dev/null
}

svc_present() { [ -x "/etc/init.d/$1" ] && echo 1 || echo 0; }
svc_enabled() { /etc/init.d/"$1" enabled  >/dev/null 2>&1 && echo 1 || echo 0; }
svc_running() { /etc/init.d/"$1" status   >/dev/null 2>&1 && echo 1 || echo 0; }

dock_present=0; has docker && dock_present=1

has_img() {
  [ "$dock_present" -eq 1 ] || return 1
  docker ps --format '{{.Image}}' 2>/dev/null | grep -q "$1"
}
any_crashing=0
docker_ps_brief() {
  [ "$dock_present" -eq 1 ] || return 0
  # 列 ChirpStack/MQTT/DB/Bridge 相關容器
  docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null \
    | grep -Ei 'chirpstack|mosquitto|gateway-bridge|redis|postgres' || true
  # 粗抓 crash/restart 字眼
  docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null \
    | grep -Ei 'Restarting|Exited' >/dev/null 2>&1 && any_crashing=1 || any_crashing=0
}

print_ports() {
  (netstat -lpun 2>/dev/null || ss -lunp 2>/dev/null) \
    | grep -E ':(1700|1883|8883|3001|5432)\b' || true
}

# 關注的 init.d 服務（依你的專案命名）
SVCS="
linxdot_chirpstack_concentratord:concentratord
linxdot_chirpstack_gateway_mesh_border:mesh_border
linxdot_chirpstack_mqtt_forwarder_as_border:mqtt_forwarder
linxdot_chirpstack_udp_forwarder:udp_forwarder
"

collect_svcs() {
  echo "$SVCS" | while IFS=: read -r name tag; do
    [ -z "$name" ] && continue
    p=$(svc_present "$name"); e=$(svc_enabled "$name"); r=$(svc_running "$name")
    when="$(log_last "$name|$tag")"
    echo "$name:$p:$e:$r:${when:-N/A}"
  done
}

# ---------- gather ----------
# Docker 角色元件
has_srv=0; has_gwb=0; has_mosq=0; has_redis=0; has_pg=0; has_rest=0
if [ "$dock_present" -eq 1 ]; then
  has_img 'chirpstack/chirpstack'                    && has_srv=1   || true
  has_img 'chirpstack/chirpstack-gateway-bridge'     && has_gwb=1   || true
  has_img 'eclipse-mosquitto'                        && has_mosq=1  || true
  has_img 'redis'                                    && has_redis=1 || true
  has_img 'postgres'                                 && has_pg=1    || true
  has_img 'chirpstack/chirpstack-rest-api'           && has_rest=1  || true
fi

# init.d 執行情況（Border 三件）
run_border=$(svc_running linxdot_chirpstack_gateway_mesh_border)
run_fwd=$(svc_running   linxdot_chirpstack_mqtt_forwarder_as_border)
run_udp=$(svc_running   linxdot_chirpstack_udp_forwarder)

# 角色判斷
role="Unknown"; reason=""
if [ $has_srv -eq 1 ] && [ $has_gwb -eq 1 ] && [ $has_mosq -eq 1 ] && [ $has_redis -eq 1 ] && [ $has_pg -eq 1 ]; then
  role="All-in-one"; reason="Docker: server+bridge+MQTT+DB"
fi
if [ $run_border -eq 1 ] || [ $run_fwd -eq 1 ] || [ $run_udp -eq 1 ]; then
  if [ "$role" = "All-in-one" ]; then
    role="All-in-one + Border"; reason="$reason; border services running"
  else
    role="Mesh Border"; reason="Border services running"
  fi
fi

# 健康狀態碼
exit_code=0
[ "$role" = "Unknown" ] && exit_code=1
[ "$dock_present" -eq 1 ] && [ "$any_crashing" -eq 1 ] && exit_code=2
[ "$role" = "All-in-one + Border" ] && exit_code=3

# ---------- output ----------
if [ "$MODE" = "json" ]; then
  echo "{"
  echo "  \"ts\": \"$(now)\","
  echo "  \"role\": \"$role\","
  echo "  \"reason\": \"${reason}\","
  echo "  \"docker\": {"
  echo "    \"present\": $(yn_json $dock_present),"
  echo "    \"chirpstack_server\": $(yn_json $has_srv),"
  echo "    \"gateway_bridge\": $(yn_json $has_gwb),"
  echo "    \"mosquitto\": $(yn_json $has_mosq),"
  echo "    \"redis\": $(yn_json $has_redis),"
  echo "    \"postgres\": $(yn_json $has_pg),"
  echo "    \"rest_api\": $(yn_json $has_rest),"
  echo "    \"any_crashing\": $(yn_json $any_crashing)"
  echo "  },"
  echo "  \"services\": ["
  first=1
  collect_svcs | while IFS=: read -r name present enabled running last; do
    [ $first -eq 0 ] && echo "    ,"
    first=0
    echo "    {\"name\":\"$name\",\"present\":$(yn_json $present),\"enabled\":$(yn_json $enabled),\"running\":$(yn_json $running),\"last_log_time\":\"$last\"}"
  done
  echo "  ]"
  echo "}"
elif [ "$MODE" = "short" ]; then
  echo "Role: $role"
  [ -n "$reason" ] && echo "Reason: $reason"
  running=$(collect_svcs | awk -F: '$4==1 {print $1}' | tr '\n' ' ')
  echo "Running: ${running:-None}"
else
  echo "==== Linxdot Quick Summary ===="
  echo "Time: $(now)"
  echo
  echo "-- init.d services --"
  printf "%-40s %-7s %-7s %-8s %s\n" "name" "present" "enabled" "running" "last-log-time"
  printf "%-40s %-7s %-7s %-8s %s\n" "----------------------------------------" "-------" "-------" "--------" "-------------------"
  collect_svcs | while IFS=: read -r name present enabled running last; do
    printf "%-40s %-7s %-7s %-8s %s\n" "$name" "$(yn $present)" "$(yn $enabled)" "$(yn $running)" "$last"
  done
  echo
  echo "-- docker services --"
  echo "present=$(yn $dock_present)  srv=$(yn $has_srv)  bridge=$(yn $has_gwb)  mqtt=$(yn $has_mosq)  redis=$(yn $has_redis)  pg=$(yn $has_pg)  rest=$(yn $has_rest)"
  docker_ps_brief
  echo
  echo "-- role --"
  echo "Role: $role"
  [ -n "$reason" ] && echo "Reason: $reason"
  echo
  echo "-- ports (1700/1883/8883/3001/5432) --"
  print_ports
fi

exit $exit_code