#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install and start lora_pkd_fwd as a background service.
# Author: Living Huang
# Date: 2025-02-23

service_file="/etc/init.d/linxdot-chirpstack-mqtt-forwarder"
script_to_run="/opt/awesome_linxdot/run_chirpstack_mqtt_forwarder.sh"

echo "Step 1: Checking if the ChirpStack MQTT forwarder service is installed..."

# Check if service file exists
if [ ! -f "$service_file" ]; then
    echo "Service not found. Creating service file..."

    cat << 'EOF' > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "chirpstack-mqtt-forwarder" "Starting ChirpStack MQTT forwarder service..."

    procd_open_instance
    procd_set_param command /opt/awesome_linxdot/run_chirpstack_mqtt_forwarder.sh
    procd_set_param respawn 3600 5 0  # respawn after 3600s (1h) if fails, with 5s delay between retries
    procd_set_param stdout 1          # redirect stdout to syslog
    procd_set_param stderr 1          # redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack-mqtt-forwarder" "Service started successfully!"
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service at boot
    "$service_file" enable

    # Start the service
    "$service_file" start
else
    echo "Service already exists. Restarting..."
    "$service_file" restart
fi

echo "Step 2: Service setup completed!"
