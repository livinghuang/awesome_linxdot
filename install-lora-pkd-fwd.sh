#!/bin/sh

# Linxdot OpenSource:
# Purpose: Install and start lora_pkt_fwd as a background service.
# Author: Living Huang
# Date: 2025-02-23

region="AS923"
service_file="/etc/init.d/linxdot-lora-pkt-fwd"
run_script="/opt/awesome_linxdot/run_lora_pkt_fwd.sh"

echo "Step 1: Checking if the LoRa Packet Forwarder service is installed..."

# Check if the service file exists
if [ ! -f "$service_file" ]; then
    echo "-------- Service not found. Creating service file..."

    cat << EOF > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "lora_pkt_fwd" "Starting LoRa Packet Forwarder service with region: ${region}..."

    procd_open_instance
    procd_set_param command "${run_script}" "${region}"
    procd_set_param respawn 3600 5 0  # Respawn after 1 hour (3600s) with 5s delay on failure
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "lora_pkt_fwd" "LoRa Packet Forwarder service started!"
}
EOF

    # Make the service script executable
    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable and start the service
    "$service_file" enable
    "$service_file" start
else
    echo "Service already exists."
fi

echo "Step 2: Service installation and start process completed!"
