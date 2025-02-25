#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start the chirpstack-mqtt-forwarder as a background service.
# Author: Living Huang
# Date: 2025-02-23
# Updated: Accepts simplified arguments (border or relay) and maps them to config files.

# --- Parameters and Variables ---

role="${1:-default}"  # Default role is 'default' if no argument is provided
service_file="/etc/init.d/linxdot-chirpstack-mqtt-forwarder"
script_to_run="/opt/awesome_linxdot/run_chirpstack_mqtt_forwarder.sh"

# Map roles to configuration files
case "$role" in
  border)
    config_file="chirpstack-mqtt-forwarder-as-gateway-mesh-border.toml"
    ;;
  relay)
    config_file="chirpstack-mqtt-forwarder-as-gateway-mesh-relay.toml"
    ;;
  *)
    config_file="chirpstack-mqtt-forwarder.toml"
    ;;
esac

echo "Step 1: Checking if the ChirpStack MQTT forwarder service is installed..."
echo "Using configuration file: $config_file"

# --- Create Service File if Not Exists ---

if [ ! -f "$service_file" ]; then
    echo "Service not found. Creating service file..."

    cat << EOF > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "chirpstack-mqtt-forwarder" "Starting ChirpStack MQTT forwarder with config: $config_file..."

    procd_open_instance
    procd_set_param command "$script_to_run" "$config_file"
    procd_set_param respawn 3600 5 0  # Restart after 3600s if fails, up to 5 retries
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack-mqtt-forwarder" "Service started successfully!"
}

stop_service() {
    logger -t "chirpstack-mqtt-forwarder" "Stopping ChirpStack MQTT forwarder service..."
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    "$service_file" enable
    echo "Service enabled to start on boot."

    "$service_file" start
    echo "Service started successfully."
else
    echo "Service already exists. Restarting service..."
    "$service_file" restart
fi

echo "Step 2: Service setup completed!"
