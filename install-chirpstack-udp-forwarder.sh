#!/bin/sh

# Linxdot OpenSource:
# Main purpose: Install and start chirpstack-udp-forwarder as a background service.
# Author: Living Huang
# Date: 2025-02-24

service_file="/etc/init.d/linxdot-chirpstack-udp-forwarder"
script_to_run="/opt/awesome_linxdot/run_chirpstack_udp_forwarder.sh"

echo "Step 1: Checking if the ChirpStack UDP forwarder service is installed..."

# Check if service file exists
if [ ! -f "$service_file" ]; then
    echo "Service not found. Creating service file..."

    cat << 'EOF' > "$service_file"
#!/bin/sh /etc/rc.common

START=99
USE_PROCD=1

start_service() {
    logger -t "chirpstack-udp-forwarder" "Starting ChirpStack UDP forwarder service..."

    procd_open_instance
    procd_set_param command /opt/awesome_linxdot/run_chirpstack_udp_forwarder.sh
    procd_set_param respawn 3600 5 0  # Respawn after 3600s (1 hour) if it fails, with a 5s delay between retries
    procd_set_param stdout 1          # Redirect stdout to syslog
    procd_set_param stderr 1          # Redirect stderr to syslog
    procd_close_instance

    logger -t "chirpstack-udp-forwarder" "Service started successfully!"
}
EOF

    chmod +x "$service_file"
    echo "Service file created and made executable."

    # Enable the service at boot
    "$service_file" enable

    # Start the service
    "$service_file" start
else
    echo "Service already exists."
fi

echo "Step 2: Service setup completed!"
