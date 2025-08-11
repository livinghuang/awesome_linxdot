#!/bin/sh
# Linxdot Login Summary (OpenWrt/BusyBox friendly)
# v1.1 — modes: table(default), --short, --json
# exit codes: 0=OK, 1=Unknown role, 2=Docker problem, 3=Role conflict (混合/衝突)
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
img_count() {
  [ "$dock_present" -eq 1 ] || { echo 0; return; }
  docker ps --format '{{.Image}}' 2>/dev/null | grep -c "$1" || true
}

any_crashing=0
docker_ps_brief() {
  [ "$dock_present" -eq 1 ] || return 0
  docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null \
    | grep -Ei 'chirpstack|mosquitto|gateway-bridge|redis|postgres' || true
  docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null \
    | grep -Ei 'Restarting|Exited' >/dev/null 2>&1 && any_crashing=1 || any_crashing=0
}

print_ports() {
  (netstat -lpun 2>/dev/null || ss -lunp 2>/dev/null) \
    | grep -E ':(1700|1883|8883|3001|5432|8080|8090)\b' || true
}

# ---------- services to watch ----------
# 已有：Border 三件 + concentratord
# 新增：Relay 兩件、Multi-Server 服務（你之後做 init.d 也能自動吃到）
SVCS="
linxdot_chirpstack_concentratord:concentratord
linxdot_chirpstack_gateway_mesh_border:mesh_border
linxdot_chirpstack_mqtt_forwarder_as_border:mqtt_forwarder
linxdot_chirpstack_udp_forwarder:udp_forwarder
linxdot_chirpstack_gateway_mesh_relay:mesh_relay
linxdot_chirpstack_mqtt_forwarder_as_relay:mqtt_forwarder_relay
linxdot_multi_server:multi_server
linxdot_chirpstack_service:multi_server_alt
"

collect_svcs() {
  echo "$SVCS" | while IFS=: read -r name tag; do
    [ -z "$name" ] && continue
    p=$(svc_present "$name"); e=$(svc_enabled "$name"); r=$(svc_running "$name")
    when="$(log_last "$name|$tag")"
    echo "$name:$p:$e:$r:${when:-N/A}"
  done
}

# ---------- gather docker features ----------
has_srv=0; has_gwb=0; has_mosq=0; has_redis=0; has_pg=0; has_rest=0
srv_count=0
if [ "$dock_present" -eq 1 ]; then
  has_img 'chirpstack/chirpstack'                    && has_srv=1   || true
  srv_count="$(img_count 'chirpstack/chirpstack')"
  has_img 'chirpstack/chirpstack-gateway-bridge'     && has_gwb=1   || true
  has_img 'eclipse-mosquitto'                        && has_mosq=1  || true
  has_img 'redis'                                    && has_redis=1 || true
  has_img 'postgres'                                 && has_pg=1    || true
  has_img 'chirpstack/chirpstack-rest-api'           && has_rest=1  || true
fi

# ---------- role detection ----------
run_border=$(svc_running linxdot_chirpstack_gateway_mesh_border)
run_fwd_b=$(svc_running linxdot_chirpstack_mqtt_forwarder_as_border)
run_udp_b=$(svc_running linxdot_chirpstack_udp_forwarder)

run_relay_mesh=$(svc_running linxdot_chirpstack_gateway_mesh_relay)
run_relay_fwd=$(svc_running linxdot_chirpstack_mqtt_forwarder_as_relay)

run_multi_svc=$(svc_running linxdot_multi_server)
run_multi_alt=$(svc_running linxdot_chirpstack_service)

role="Unknown"; reason=""
# All-in-one (Docker stack 齊全)
if [ $has_srv -eq 1 ] && [ $has_gwb -eq 1 ] && [ $has_mosq -eq 1 ] && [ $has_redis -eq 1 ] && [ $has_pg -eq 1 ]; then
  role="All-in-one"; reason="Docker: server+bridge+MQTT+DB"
fi
# Border
if [ $run_border -eq 1 ] || [ $run_fwd_b -eq 1 ] || [ $run_udp_b -eq 1 ]; then
  if [ "$role" = "All-in-one" ]; then
    role="All-in-one + Border"; reason="$reason; border services running"
  elif [ "$role" = "Unknown" ]; then
    role="Mesh Border"; reason="border services running"
  else
    role="$role + Border"; reason="$reason; border services running"
  fi
fi
# Relay
relay_active=0
[ $run_relay_mesh -eq 1 ] || [ $run_relay_fwd -eq 1 ] && relay_active=1
if [ $relay_active -eq 1 ]; then
  if [ "$role" = "Unknown" ]; then
    role="Mesh Relay"; reason="relay services running"
  else
    role="$role + Relay"; reason="$reason; relay services running"
  fi
fi
# Multi-Server
multi_active=0
[ $run_multi_svc -eq 1 ] || [ $run_multi_alt -eq 1 ] && multi_active=1
# 若有 2 個以上 chirpstack server 容器，也視為 multi-server
if [ "$srv_count" -ge 2 ]; then multi_active=1; fi
if [ $multi_active -eq 1 ]; then
  if [ "$role" = "Unknown" ]; then
    role="Multi-Server"; reason="multi-server service/containers active"
  else
    role="$role + Multi-Server"; reason="$reason; multi-server active"
  fi
fi

# 健康碼
exit_code=0
[ "$role" = "Unknown" ] && exit_code=1
[ "$dock_present" -eq 1 ] && [ "$any_crashing" -eq 1 ] && exit_code=2
# 衝突：同時有 All-in-one +（Border 或 Relay 或 Multi-Server）
echo "$role" | grep -Eq 'All-in-one' && echo "$role" | grep -Eq 'Border|Relay|Multi-Server' && exit_code=3

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
  echo "    \"server_container_count\": ${srv_count:-0},"
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
  echo "present=$(yn $dock_present)  srv=$(yn $has_srv)  srv_count=${srv_count:-0}  bridge=$(yn $has_gwb)  mqtt=$(yn $has_mosq)  redis=$(yn $has_redis)  pg=$(yn $has_pg)  rest=$(yn $has_rest)"
  docker_ps_brief
  echo
  echo "-- role --"
  echo "Role: $role"
  [ -n "$reason" ] && echo "Reason: $reason"
  echo
  echo "-- ports (1700/1883/8883/3001/5432/8080/8090) --"
  print_ports
fi

exit $exit_code
